# SimpleERC20ProxyContract

1) This project intends to implement the ERC20 contract by enabling the upgrade of smart contract by using the concept of the proxy.

2) a) Deploy Registry.sol and ERC20Proxy.sol.
   b) Execute 'setLogicContract' function of Registry.sol by passing the contract address of the ERCProxy.sol.

3) Registry.sol acts as a proxy.

4) While writing the logic, in order to keep the things simple, a user has been allowed to initiate only single withdrawal request at a time. And once the      withdrawal request is cancelled, it cannot be confirmed again.




