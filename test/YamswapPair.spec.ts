import chai, {expect} from 'chai'
import {Contract} from 'ethers'
import { BigNumber, bigNumberify } from 'ethers/utils'
import { solidity, MockProvider, createFixtureLoader } from 'ethereum-waffle'
import {pairFixture} from './shared/fixtures'
import { expandTo18Decimals } from './shared/utilities'
import {AddressZero} from 'ethers/constants'

const MINIMUM_LIQUIDITY = bigNumberify(10).pow(3)

chai.use(solidity)

const overrides = {
  gasLimit: 9999999
}

describe('YamswapPair', () => {
  const provider = new MockProvider({
    hardfork: 'istanbul',
    mnemonic: 'horn horn horn horn horn horn horn horn horn horn horn horn',
    gasLimit: 9999999
  })

  const [wallet, other] = provider.getWallets()
  const loadFixture = createFixtureLoader(provider, [wallet])

  let factory: Contract
  let token0: Contract
  let token1: Contract
  let pair: Contract

  beforeEach(async () => {
    const fixture = await loadFixture(pairFixture)
    factory = fixture.factory
    token0 = fixture.token0
    token1 = fixture.token1
    pair = fixture.pair
  })

  it('mint', async () => {
    const token0Amount = expandTo18Decimals(1)
    const token1Amount = expandTo18Decimals(4)
    await token0.transfer(pair.address, token0Amount)
    await token1.transfer(pair.address, token1Amount)

    const expectedLiquidity = expandTo18Decimals(2)
    await expect(pair.mint(wallet.address, overrides))
      .to.emit(pair, 'Transfer')
      .withArgs(AddressZero, AddressZero, MINIMUM_LIQUIDITY)
      .to.emit(pair, 'Transfer')
      .withArgs(AddressZero, wallet.address, expectedLiquidity.sub(MINIMUM_LIQUIDITY))
      .to.emit(pair, 'Sync')
      .withArgs(token0Amount, token1Amount)
      .to.emit(pair, 'Mint')
      .withArgs(wallet.address, token0Amount, token1Amount)

    expect(await pair.totalSupply()).to.eq(expectedLiquidity)
    expect(await pair.balanceOf(wallet.address)).to.eq(expectedLiquidity.sub(MINIMUM_LIQUIDITY))
    expect(await token0.balanceOf(pair.address)).to.eq(token0Amount)
    expect(await token1.balanceOf(pair.address)).to.eq(token1Amount)
    const reserves = await pair.getReserves()
    expect(reserves[0]).to.eq(token0Amount)
    expect(reserves[1]).to.eq(token1Amount)
  })

  async function addLiquidity(token0Amount: BigNumber, token1Amount: BigNumber) {
    await token0.transfer(pair.address, token0Amount)
    await token1.transfer(pair.address, token1Amount)
    await pair.mint(wallet.address, overrides)
  }

  // TODO AssertionError
  // const swapTestCases: BigNumber[][] = [
  //   [1, 5, 10, '1662497915624478906'],
  //   [1, 10, 5, '453305446940074565'],
  //
  //   [2, 5, 10, '2851015155847869602'],
  //   [2, 10, 5, '831248957812239453'],
  //
  //   [1, 10, 10, '906610893880149131'],
  //   [1, 100, 100, '987158034397061298'],
  //   [1, 1000, 1000, '996006981039903216']
  // ].map(a => a.map(n => (typeof n === 'string' ? bigNumberify(n) : expandTo18Decimals(n))))
  // swapTestCases.forEach((swapTestCase, i) => {
  //   it(`getInputPrice:${i}`, async () => {
  //     const [swapAmount, token0Amount, token1Amount, expectedOutputAmount] = swapTestCase
  //     await addLiquidity(token0Amount, token1Amount)
  //     await token0.transfer(pair.address, swapAmount)
  //     await expect(pair.swap(0, expectedOutputAmount.add(1), wallet.address, '0x', overrides)).to.be.revertedWith(
  //       'Yamswap: K'
  //     )
  //     await pair.swap(0, expectedOutputAmount, wallet.address, '0x', overrides)
  //   })
  // })

  // TODO AssertionError
  // const optimisticTestCases: BigNumber[][] = [
  //   ['997000000000000000', 5, 10, 1], // given amountIn, amountOut = floor(amountIn * .997)
  //   ['997000000000000000', 10, 5, 1],
  //   ['997000000000000000', 5, 5, 1],
  //   [1, 5, 5, '1003009027081243732'] // given amountOut, amountIn = ceiling(amountOut / .997)
  // ].map(a => a.map(n => (typeof n === 'string' ? bigNumberify(n) : expandTo18Decimals(n))))
  // optimisticTestCases.forEach((optimisticTestCase, i) => {
  //   it(`optimistic:${i}`, async () => {
  //     const [outputAmount, token0Amount, token1Amount, inputAmount] = optimisticTestCase
  //     await addLiquidity(token0Amount, token1Amount)
  //     await token0.transfer(pair.address, inputAmount)
  //     await expect(pair.swap(outputAmount.add(1), 0, wallet.address, '0x', overrides)).to.be.revertedWith(
  //       'Yamswap: K'
  //     )
  //     await pair.swap(outputAmount, 0, wallet.address, '0x', overrides)
  //   })
  // })

  it('swap: token0', async () => {
    const token0Amount = expandTo18Decimals(5)
    const token1Amount = expandTo18Decimals(10)
    await addLiquidity(token0Amount, token1Amount)

    const swapAmount = expandTo18Decimals(1)
    const expectedOutputAmount = bigNumberify('1662497915624478906')
    await token0.transfer(pair.address, swapAmount)
    await expect(pair.swap(0, expectedOutputAmount, wallet.address, '0x', overrides))
      .to.emit(token1, 'Transfer')
      .withArgs(pair.address, wallet.address, expectedOutputAmount)
      .to.emit(pair, 'Sync')
      .withArgs(token0Amount.add(swapAmount), token1Amount.sub(expectedOutputAmount))
      .to.emit(pair, 'Swap')
      .withArgs(wallet.address, swapAmount, 0, 0, expectedOutputAmount, wallet.address)
  })
})