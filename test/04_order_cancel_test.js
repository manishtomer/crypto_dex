var fixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
var exchange = artifacts.require("./Exchange.sol");

contract('cancel order test', async(accounts) => {
    it('Order can be canceled', async () => {
        let exchangeInstance = await exchange.deployed();
        await exchangeInstance.depositEther({from: accounts[0], value: web3.toWei(3, "ether")});
        let tokenInstance = await fixedSupplyToken.deployed();
        await exchangeInstance.addToken("Fixed", tokenInstance.address);
        await tokenInstance.approve(exchangeInstance.address, 2000);
        await exchangeInstance.depositToken("Fixed", 2000);

        let txResult = await exchangeInstance.buyToken("Fixed", 1000000, 100);
        let orderKey = txResult.logs[0].args._orderKey;
        let orderBook = await exchangeInstance.getBuyOrderBook.call("Fixed");
        assert.equal (orderBook[0].length, 1, "Orderbook should have 1 buy offer");
        assert.equal (orderBook[1].length, 1, "Orderbook should have 1 buy volume element");
        await exchangeInstance.cancelOrder("Fixed", false, 1000000, orderKey);
        orderBook = await exchangeInstance.getBuyOrderBook.call("Fixed");
        assert.equal (orderBook[0].length, 1, "Orderbook should have 0 buy offer");
        assert.equal (orderBook[1][0], 0, "Orderbook should have 0 buy volume element");
    });
});