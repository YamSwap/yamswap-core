// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

interface IYamswapMigrator {
    function migrate(address token, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external;
}
