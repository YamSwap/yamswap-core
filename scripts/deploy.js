const { ethers } = require("hardhat");

async function main() {

    const YamswapFactory = await ethers.getContractFactory("YamswapFactory");
    const YamswapRouter01 = await ethers.getContractFactory("YamswapRouter01");
    const feeToSetter = '0x339182FD236626d3880F443F7435D26BD1bA6eA5';
    const WETH = {
        mainnet:'0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
        ropsten:'0xc778417E063141139Fce010982780140Aa0cD5Ab',
        rinkeby:'0xc778417E063141139Fce010982780140Aa0cD5Ab',
        goerli:'0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6',
        kovan:'0xd0A1E359811322d97991E03f863a0C30C2cF029C'
    };

    const yamswapFactory = await YamswapFactory.deploy(feeToSetter);
    const yamswapRouter01 = await YamswapRouter01.deploy(yamswapFactory.address, WETH.ropsten);

    console.log("yamswapFactory deployed to:", yamswapFactory.address);
    console.log("yamswapRouter01 deployed to:", yamswapRouter01.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });