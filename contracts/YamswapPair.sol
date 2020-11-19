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
import "./interface/IYamswapFactory.sol";
import "./libraries/Math.sol";
import "./interface/IYamswapPair.sol";
import "./YamswapERC20.sol";

contract YamswapPair is IYamswapPair, YamswapERC20{

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

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
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

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IYamswapFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast;
        if(feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(reserve0);
        uint amount1 = balance1.sub(reserve1);

        bool feeOn =_mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply;
        if(_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'Yamswap: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();   // 节约gas
        address _token0 = token0;                                   // 节约gas
        address _token1 = token1;                                   // 节约gas
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // 节约gas，必须在这里定义，因为在_mintFee中totalSupply已经被更新了
        amount0 = liquidity.mul(balance0) / _totalSupply; // 使用余额确保按比例分配
        amount1 = liquidity.mul(balance1) / _totalSupply; // 使用余额确保按比例分配
        require(amount0 > 0 && amount1 > 0, 'Yamswap: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
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
            require(to != _token0 && to != _token1, 'Yamswap: INVALID_TO');
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);
            if (data.length > 0) IYamswapCallee(to).yamswapCall(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
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

    // 强制余额与储备金相等
    function skim(address to) external lock {
        address _token0 = token0;
        address _token1 = token1;
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // 强制储备金与余额相等
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

}
