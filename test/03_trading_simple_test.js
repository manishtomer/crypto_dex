// var fixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
// var exchange = artifacts.require("./Exchange.sol");

// contract('Order test', async(accounts) => {
//     before ( async () => {
//         myExchangeInstance = await exchange.deployed();
//         await myExchangeInstance.depositEther({from: accounts[0], value: web3.toWei(3, "ether")});
//         tokenInstance = await fixedSupplyToken.deployed();
//         await myExchangeInstance.addToken("Fixed", tokenInstance.address);
//         await tokenInstance.approve(myExchangeInstance.address, 2000);
//         await myExchangeInstance.depositToken("Fixed", 2000);
//     });

//     it('should be possible to add a limit order', async () => {
//         let orderBook = await myExchangeInstance.getBuyOrderBook.call("Fixed");
//         assert.equal(orderBook.length, 2, "BuyOrderbook should have 2 elements");
//         assert.equal(orderBook[0].length, 0, "BuyOrderbook should have 0 buy offers");
//         let txResult = await myExchangeInstance.buyToken("Fixed", 1000000, 100);

//         assert.equal(txResult.logs.length, 1, "There should have been one log message");
//         assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated", "Should be BuyOrderCreated log event");

//         orderBook = await myExchangeInstance.getBuyOrderBook.call("Fixed");
//         assert.equal (orderBook[0].length, 1, "Orderbook should have 1 buy offer");
//         assert.equal (orderBook[1].length, 1, "Orderbook should have 1 buy volume element");

//     });

//     it('should be possible to add two sell orders', async() => {
//         let txResult = await myExchangeInstance.sellToken("Fixed", 1000000, 100);
//         assert.equal(txResult.logs.length, 1, "There should have been one log message");
//         assert.equal(txResult.logs[0].event, "LimitSellOrderCreated", "Should be SellOrderCreated log event");

//         txResult = await myExchangeInstance.sellToken("Fixed", 1000001, 200);
//         assert.equal(txResult.logs.length, 1, "There should have been one log message");
//         assert.equal(txResult.logs[0].event, "LimitSellOrderCreated", "Should be SellOrderCreated log event");

//         sellOrderBook = await myExchangeInstance.getSellOrderBook.call("Fixed");
//         assert.equal(sellOrderBook[0].length, 2, "SellOrderBook should have 2 sell offer");
//         assert.equal(sellOrderBook[1].length, 2, "SellOrderBook should have 2 volume element");
//     });
// });