/**
 * @program: yamswap-core
 * @description: 
 * @author: a186r
 * @create: 2020-10-21
 **/

pragma solidity >=0.4.21 <0.7.0;

import "./libraries/SafeMath.sol";
import "./libraries/UQ112x112.sol";

contract YamswapPair {

    using SafeMath for uint;
    using UQ112x112 for uint224;

    // 定义一个最低流动性
    uint public constant MINIMUM_LIQUIDITY = 10**3;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address, uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // 使用单个存储插槽，可通过getReserves访问
    uint112 private reserve1;           // 使用单个存储插槽，可通过getReserves访问
    uint32  private blockTimestampLast; // 使用单个存储插槽，可通过getReserves访问

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast;  // reserve0 * reserve1，AMM中的K值，截止最后一次提供流动性

    uint private unlocked = 1;

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
}
