import { Contract, Wallet } from 'ethers'
import { Web3Provider } from 'ethers/providers'

import ERC20 from '../../build/ERC20.json'
import YamswapFactory from '../../build/YamswapFactory.json'
import YamswapPair from '../../build/YamswapPair.json'
import { deployContract } from 'ethereum-waffle'

interface FactoryFixture{
  factory: Contract
}

const overrides = {
  gasLimit: 9999999
}

export async function factoryFixture(_: Web3Provider, [wallet]: Wallet[]): Promise<FactoryFixture> {
  const factory = await deployContract(wallet, YamswapFactory, [wallet.address], overrides)
  return { factory }
}

interface PairFixture extends FactoryFixture {
  token0: Contract
  token1: Contract
  pair: Contract
}