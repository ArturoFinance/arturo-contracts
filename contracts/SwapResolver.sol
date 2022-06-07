// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./interfaces/IResolver.sol";
import "./interfaces/ISwapWorkflow.sol";

contract SwapResolver is IResolver {
    ISwapWorkflow swapWorkflow;

    constructor(address _swapWorkflow) {
        swapWorkflow = ISwapWorkflow(_swapWorkflow);
    }

    function checker()
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        uint256 lastExecuted = swapWorkflow.lastExecuted();

        // solhint-disable not-rely-on-time
        canExec = (block.timestamp - lastExecuted) > 180;

        execPayload = abi.encodeWithSelector(
            ISwapWorkflow.swap.selector,
            address(0x6EB662716e3FF6e035Fc0c629eFD672dCb7b0341),
            address(0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889),
            address(0xcB1e72786A6eb3b44C2a2429e317c8a2462CFeb1),
            uint256(260000000000000),
            uint256(10000000000)
        );
    }
}
