// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./DexPair.sol";

/**
 * @title DexFactory
 * @dev The factory contract for the Art DEX. 
 * Responsible for creating pairs and managing fee settings.
 */
contract DexFactory is Ownable {
    address public feeTo;
    address public feeToSetter;

    // Mapping to track pairs: tokenA => tokenB => pairAddress
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) Ownable(msg.sender) {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

/* Creates liquidity pair for two tokens  */

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "Dex: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Dex: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "Dex: PAIR_EXISTS");

        // Deployment logic for the Pair contract goes here (usually via create2)
        // For brevity in this initial component, we focus on the Factory structure.
        
        // ... [Pair Deployment Code] ...

        bytes memory bytecode = type(DexPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // Initialize the pair with the two tokens
        IDexPair(pair).initialize(token0, token1);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in both directions
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