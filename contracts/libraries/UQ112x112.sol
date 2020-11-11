pragma solidity >=0.4.21 <0.7.0;

library UQ112x112 {
    // uint224 = 2**112;
    uint224 constant Q112 = 2**112;

    // 将一个uint112编码为UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z){
        z = uint224(y) * Q112;
    }

    // UQ112x112除以uint112，返回一个UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z){
        z = x / uint224(y);
    }
}
