// SPDX-License-Identifier: MIT

/**
 * @program: yamswap-core
 * @description: 
 * @author: a186r
 * @create: 2020-10-21
 **/

pragma solidity >=0.4.21 <0.9.0;

// import "./interface/IYamswapFactory.sol";
import "./YamswapPair.sol";
import "./interface/IYamswapPair.sol";


contract YamswapFactory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'Yamswap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Yamswap: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Yamswap: PAIR_EXISTS');
        bytes memory bytecode = type(YamswapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IYamswapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
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
