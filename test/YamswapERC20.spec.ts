import {Contract} from 'ethers'
import {solidity, MockProvider, deployContract} from "ethereum-waffle";
import {expandTo18Decimals} from "./shared/utilities";

import ERC20 from '../build/ERC20.json'
chai.use(solidity)

const TOTAL_SUPPLY = expandTo18Decimals(10000)
const TEST_AMOUNT = expandTo18Decimals(10)

describe('YamswapERC20', () => {
    const provider = new MockProvider({
        hardfork: 'istanbul',
        mnemonic: 'horn horn horn horn horn horn horn horn horn horn horn horn',
        gasLimit: 9999999
    })
    const [wallet, other] = provider.getWallets()

    let token: Contract
    beforeEach(async () => {
        token = await deployContract(wallet, ERC20, [TOTAL_SUPPLY])
    })
})