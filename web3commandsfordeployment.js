
Note: these CLI commands assume truffle ^4.0.0 and web3.js 0.20.0
and it is not exhaustive

CadasterAndNotary.deployed().then(function(res){notary = res})

var acc1 = web3.eth.accounts[0];
var acc2 = web3.eth.accounts[1];
var acc3 = web3.eth.accounts[2];
var acc4 = web3.eth.accounts[3];
var acc5 = web3.eth.accounts[4];
var acc6 = web3.eth.accounts[5];
var acc7 = web3.eth.accounts[6];
var acc8 = web3.eth.accounts[7];
var acc9 = web3.eth.accounts[8];
var acc10 = web3.eth.accounts[9];

notary.addProperties(acc1, 12345, 1, false)
notary.addProperties(acc2, 67890, 2, false)
notary.addProperties(acc3, 19891989, 1, true)

notary.forIndex(0)
// acc10 is the buyer and acc1 is the seller
notary.initiateTransaction(acc10, acc1, 0, 198989, 123000, {from:acc1})

notary.downPayment(1234, {from:acc1, value:1234})
notary.downPayment(1234, {from:acc10, value:1234})

notary.agreementForPreliminary({from:acc1})
notary.agreementForPreliminary({from:acc10})

//second argument of next 2 commands should be > (now - starttime) or it fails*/
notary.sellerProposal(19898900, 15142475230, {from:acc1})
notary.buyerProposal(19898900, 15142475230, {from:acc10})

notary.increaseBuyerBalance({from:acc10, value:1234567890})

notary.agreementForTransaction({from:acc1})
notary.agreementForTransaction({from:acc10})

notary.claimBalance(acc1, {from:acc1})
notary.claimBalance(acc10, {from:acc10})