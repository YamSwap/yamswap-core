pragma solidity >=0.4.21 <0.7.0;

interface IYamswapCallee {
    function yamswapCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
