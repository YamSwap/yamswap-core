/**
 * @program: yamswap-core
 * @description: 
 * @author: a186r
 * @create: 2020-10-21
 **/

pragma solidity >=0.4.21 <0.7.0;

contract YamswapFactory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        return address(0);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'Yamswap: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'Yamswap: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
