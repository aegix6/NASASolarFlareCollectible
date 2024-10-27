
import { artifacts, ethers, run } from 'hardhat';
import { JsonApiExampleContract } from '../typechain-types';
import { JsonApiExampleInstance } from "../typechain-types/contracts/web2WeatherInteractor.sol/JsonApiExample";
const JsonApiExample: JsonApiExampleContract = artifacts.require('JsonApiExample');


const { NASA_API_KEY } = process.env

const VERIFIER_SERVER_URL = "http://localhost:8000/IJsonApi/prepareResponse";

// Function to format date as "YYYY-MM-DD"
function formatDate(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}

function buildNasaApiUrlForToday() {
    const today = new Date();
    const formattedDate = formatDate(today);
    const apiKey = "xxxxxxxx"; //dummy
    return `https://api.nasa.gov/DONKI/FLR?startDate=${formattedDate}&endDate=${formattedDate}&api_key=${apiKey}`;
}



async function getAttestationData(timestamp: number): Promise<any> {


    
    const nasaApiUrl = buildNasaApiUrlForToday(); // Get the URL for today’s date

    return await (await fetch(VERIFIER_SERVER_URL, {
        method: "POST",
        headers: { "X-API-KEY": "12345", "Content-Type": "application/json" },
        body: JSON.stringify({
            "attestationType": "0x4a736f6e41706900000000000000000000000000000000000000000000000000",
            "sourceId": "0x5745423200000000000000000000000000000000000000000000000000000000",
            "messageIntegrityCode": "0x0000000000000000000000000000000000000000000000000000000000000000",
            "requestBody": {
                "url": nasaApiUrl, // Use the generated URL here
                "postprocessJq": "{NasaFlareID:.flrID,beginTime:(.beginTime|strptime(\"%Y-%m-%dT%H:%MZ\")|mktime),peakTime:(.peakTime|strptime(\"%Y-%m-%dT%H:%MZ\")|mktime),endTime:(.endTime|strptime(\"%Y-%m-%dT%H:%MZ\")|mktime // 0),classType:.classType,sourceLocation:.sourceLocation,activeRegionNum:.activeRegionNum,note:.note,btcprice:\"500000.00\",flrprice:\"7.00\",xrpprice:\"589.00\"}",
                "abi_signature": "{\"struct SolarFlare\":{\"NasaFlareID\":\"string\",\"beginTime\":\"uint256\",\"peakTime\":\"uint256\",\"endTime\":\"uint256\",\"classType\":\"string\",\"sourceLocation\":\"string\",\"activeRegionNum\":\"uint256\",\"note\":\"string\",\"btcprice\":\"string\",\"flrprice\":\"string\",\"xrpprice\":\"string\"}}"
            }
        })
    })).json();
    
    
}




async function main() {
    const attestationData = await getAttestationData(1729858394);

    console.log(attestationData.response);

    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const jsonApi: JsonApiExampleInstance = await JsonApiExample.at("0xRealAddress") 

    await jsonApi.addSolarFlare(attestationData.response);

    try {
        const result = await run("verify:verify", {
            address: jsonApi.address,
            constructorArguments: [],
        })

        console.log(result)
    } catch (e: any) {
        console.log(e.message)
    }


}

main().then(() => process.exit(0))
