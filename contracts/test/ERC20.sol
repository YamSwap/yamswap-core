/**
 * @program: yamswap-core
 * @description: 
 * @author: a186r
 * @create: 2020-11-16
 **/

pragma solidity >=0.4.21 <0.7.0;

import "../YamswapERC20.sol";

contract ERC20 is YamswapERC20 {
    constructor(uint _totalSupply) public {
        _mint(msg.sender, _totalSupply);
    }
}
