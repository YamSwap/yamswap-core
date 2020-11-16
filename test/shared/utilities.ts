import {
    keccak256,
    toUtf8Bytes,
    BigNumber,
    bigNumberify,
    defaultAbiCoder,
    solidityPack,
    getAddress
} from "ethers/utils";
import {solidity} from "ethereum-waffle";

const PERMIT_TYPEHASH = keccak256(
    toUtf8Bytes('Permit(address owner, address spender, uint256 value, uint256 nonce, uint256 deadline)')
)

export function expandTo18Decimals(n: number): BigNumber {
    return bigNumberify(n).mul(bigNumberify(10).pow(18))
}

function getDomainSeparator(name: string, tokenAddress: string) {
    return keccak256(
        defaultAbiCoder.encode(
            ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
            [
                keccak256(toUtf8Bytes('EIP712Domain(string name, string version, uint256 chainId, address verfyingContract')),
                keccak256(toUtf8Bytes(name)),
                keccak256(toUtf8Bytes('1')),
                1,
                tokenAddress
            ]
        )
    )
}

export function getCreate2Address(
    factoryAddress: string,
    [tokenA, tokenB]: [string, string],
    bytecode: string
): string {
    const [token0, token1] = tokenA > tokenB ? [tokenA, tokenB] : [tokenB, tokenA]
    const create2Inputs = [
        '0xff',
        factoryAddress,
        keccak256(solidityPack(['address', 'address'], [token0, token1])),
        keccak256(bytecode)
    ]
    const sanitizedInputs = `0x${create2Inputs.map(i => i.slice(2)).join('')}`
    return getAddress(`0x${keccak256(sanitizedInputs).slice(-40)}`)
}