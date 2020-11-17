import chai, {expect} from 'chai'
import { BigNumber, bigNumberify } from 'ethers/utils'
import { solidity, MockProvider } from 'ethereum-waffle'

const MINIMUM_LIQUIDITY = bigNumberify(10).pow(3)

chai.use(solidity)

const override = {
  gasLimit: 9999999
}

describe('YamswapPair', () => {
  const provider = new MockProvider({
    hardfork: 'istanbul',
    mnemonic: 'horn horn horn horn horn horn horn horn horn horn horn horn',
    gasLimit: 9999999
  })

  const [wallet, other] = provider.getWallets()
})