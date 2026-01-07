// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol"; // For .symbol()
import "./DexPair.sol";

interface IDexPair {
    function initialize(address, address, string calldata, string calldata) external;
}

contract DexFactory is Ownable {
    address public feeTo;
    address public feeToSetter;

    // Use IMMUTABLE for 50-year flexibility across different chains/testnets
    address public immutable ART;
    address public immutable WETH;
    address public immutable TAIKO;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _art, address _weth, address _taiko, address _feeToSetter) Ownable(msg.sender) {
        ART = _art;
        WETH = _weth;
        TAIKO = _taiko;
        feeToSetter = _feeToSetter;
        feeTo = _feeToSetter; 
    }
    
    function getSisterPair(address tokenA, address tokenB) external view returns (address) {
        if (tokenA == ART) {
            if (tokenB == WETH) return getPair[ART][TAIKO];
            if (tokenB == TAIKO) return getPair[ART][WETH];
        } else if (tokenB == ART) {
            if (tokenA == WETH) return getPair[ART][TAIKO];
            if (tokenA == TAIKO) return getPair[ART][WETH];
        }
        return address(0);
    }  

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "Dex: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(getPair[token0][token1] == address(0), "Dex: PAIR_EXISTS");

        bytes memory bytecode = type(DexPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // FETCH SYMBOLS: This creates your ART-ETH-LP and ART-TAIKO-LP labels
        string memory sym0 = IERC20Metadata(token0).symbol();
        string memory sym1 = IERC20Metadata(token1).symbol();
        
        string memory name = string(abi.encodePacked(sym0, "/", sym1, " LP"));
        string memory symbol = string(abi.encodePacked(sym0, "-", sym1, "-LP"));
        
        IDexPair(pair).initialize(token0, token1, name, symbol);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "Dex: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "Dex: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }   
}