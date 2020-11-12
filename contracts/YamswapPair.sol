/**
 * @program: yamswap-core
 * @description: 
 * @author: a186r
 * @create: 2020-10-21
 **/

pragma solidity >=0.4.21 <0.7.0;

import "./libraries/SafeMath.sol";
import "./libraries/UQ112x112.sol";
import "./interface/IERC20.sol";
import "./interface/IYamswapCallee.sol";

contract YamswapPair {

    using SafeMath for uint;
    using UQ112x112 for uint224;

    // 定义一个最低流动性
    uint public constant MINIMUM_LIQUIDITY = 10**3;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address, uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // token0的储量，可通过getReserves访问
    uint112 private reserve1;           // token1的储量，可通过getReserves访问
    uint32  private blockTimestampLast; // 使用单个存储插槽，可通过getReserves访问

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast;  // reserve0 * reserve1，AMM中的K值，截止最后一次提供流动性

    uint private unlocked = 1;

    // 防止重入攻击
    modifier lock(){
        require(unlocked == 1, 'Yamswap: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        // abi.encodeWithSelector 允许通过函数的名称来调用函数
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Yamswap: TRANSFER_FAILED');
    }

    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    // 部署时由工厂模式调用一次
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'Yamswap: FORBIDDEN');
        token0 = _token0;
        token1 = _token1;
    }

    // 更新储备，并且在每个区块第一次调用时累计价格，这里涉及到时间加权的平均价格计算
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        // 判断balance的值是否溢出
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'Yamswap: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if(timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'Yamswap: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // 节约gas
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'Yamswap: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;

        // 处理_token{0,1},避免了堆栈过深的错误
        {
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != token1, 'Yamswap: INVALID_TO');
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);
            if (data.length > 0) IYamswapCallee(to).yamswapCall(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        uint amount0In = balance0 > reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'Yamswap: INSUFFICIENT_INPUT_AMOUNT');

        // 存储更新后的的储备金，防止堆栈过深
        {
            uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'Yamswap: K');
        }
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

}
