# NASA Solar Flare Collectibles

This is a project using both the Flare Data Connector to get external web2 data from the NASA open API to store inside of a deployed smart contract, 

and also the FTSO to get realtime price data of FLR/BTC and XRP.


This is all then stored inside an ERC721 contract and becomes a unique collectible NFT. 

Anyone can make a submission from the front-end using the API call, however, since NASA keeps each recorded solar flare with a unique ID, the contract checks for this, and will only 
mint a new NFT if that particular unique flare has not been already submitted. 

