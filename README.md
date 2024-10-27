# NASA Solar Flare Collectibles

This is a project using both the Flare Data Connector to get external web2 data from the NASA open API to store inside of a deployed smart contract, 

and also the FTSO to get realtime price data of FLR/BTC and XRP.


This is all then stored inside an ERC721 contract and becomes a unique collectible NFT. 

Anyone can make a submission from the front-end using the API call, however, since NASA keeps each recorded solar flare with a unique ID, the contract checks for this, and will only 
mint a new NFT if that particular unique flare has not been already submitted. 

https://coston2-explorer.flare.network/token/0x25A10d80bce9A48feAa199EE148Da12F5D4266aC/instance/0?tab=metadata


It is Live with a working Token Tracker and on-chain metadata generated from the stats within the struct. 

Unforunately I could not get the data connector to do the final pushings due to my hardware dying while running the verifier server locally and trying to run the api submitter. 

I hope this 98.5% complete project is enough to show off the proof of concept. 

