import { transactor } from 'eth-components/functions';
import { EthComponentsSettingsContext } from 'eth-components/models';
import { useContractLoader, useContractReader, useGasPrice } from 'eth-hooks';
import { useEthersContext } from 'eth-hooks/context';
import { ethers } from 'ethers';
import React, { useState, FC, useContext, useEffect } from 'react';
import { HelloWorld, Fireplace } from '~~/generated/contract-types';
import { useAppContracts } from '../main/hooks/useAppContracts';

export interface YuleLogProps {}

export const YuleLog: FC<YuleLogProps> = (props) => {
  const FireplaceContract = 'Fireplace';
  const ethersContext = useEthersContext();
  const [allLogs, setAllLogs] = useState({});
  const [filteredLogs, setFilteredLogs] = useState([]);

  const signer = ethersContext.signer;
  const address = ethersContext.account ?? '';

  const ethComponentsSettings = useContext(EthComponentsSettingsContext);
  const gasPrice = useGasPrice(ethersContext.chainId, 'fast');
  const tx = transactor(ethComponentsSettings, ethersContext?.signer, gasPrice);
  const appContractConfig = useAppContracts();

  const readContracts = useContractLoader(appContractConfig);
  const writeContracts = useContractLoader(appContractConfig, ethersContext?.signer);

  const FireRead = readContracts[FireplaceContract] as Fireplace;

  const FireWrite = writeContracts[FireplaceContract] as Fireplace;

  const handleMintLog = async () => {
    try {
      const price = await FireRead.price();

      const txCur = await tx?.(FireWrite.mintLog({ value: price }));

      console.log(txCur);
    } catch (e) {
      console.log('Mint failed', e);
    }
  };

  const getBurnTime = async (logId: string) => {
    try {
      const time = await FireRead.getBurnTime(logId);
      const now = await FireRead.getCurrentTimestamp();
      const days = await FireRead.getDays(logId);
      // const mapping = await FireRead.getMapping(logId);
      // console.log(ethers.BigNumber.from(time).toString());
      console.log(ethers.BigNumber.from(days).toString());
      // console.log(ethers.BigNumber.from(mapping).toString());
      // ethers.BigNumber.from(time).toString()
      // console.log(ethers.BigNumber.from(time).toString());
      // console.log(ethers.BigNumber.from(now).toString());
      // var difference = (ethers.BigNumber.from(now) - ethers.BigNumber.from(time)) / 60;
      // var minutesDifference = Math.floor(difference);
      // console.log(minutesDifference);
      const timeString = new Date(time.toNumber() * 1000).toLocaleString();
      // console.log(timeString);
      return time;
    } catch (e) {
      console.log('getBurnTime failed', e);

      return 0;
    }
  };

  const startBurn = async (logId: string) => {
    try {
      const txCur = await tx?.(FireWrite.startBurnTime(logId));
      console.log(txCur);
    } catch (e) {
      console.log('startBurn failed', e);
    }
  };

  const fetchMetadataAndUpdate = async (id) => {
    try {
      const tokenURI = await FireRead.tokenURI(id);
      const jsonManifestString = atob(tokenURI.substring(29));

      try {
        const jsonManifest = JSON.parse(jsonManifestString);
        const collectibleUpdate = {};
        collectibleUpdate[id] = { id: id, uri: tokenURI, ...jsonManifest };

        setAllLogs((i) => ({ ...i, ...collectibleUpdate }));
      } catch (e) {
        console.log(e);
      }
    } catch (e) {
      console.log(e);
    }
  };

  const updateYourOldEnglish = async () => {
    const balance = await FireRead.balanceOf(address);

    for (let tokenIndex = 0; tokenIndex < balance; tokenIndex++) {
      try {
        const tokenId = await FireRead.tokenOfOwnerByIndex(address, tokenIndex);
        fetchMetadataAndUpdate(tokenId);
      } catch (e) {
        console.log(e);
      }
    }
  };

  useEffect(() => {
    const filteredLogs = Object.values(allLogs).sort((a, b) => a.id - b.id);
    setFilteredLogs(filteredLogs);
  }, [allLogs]);

  return (
    <div>
      <button className="btn mr-10 mt-5" onClick={handleMintLog}>
        Mint Log 🪵
      </button>
      <button className="btn mt-5" onClick={updateYourOldEnglish}>
        Update Logs 🔄
      </button>
      <div className="grid grid-cols-4 gap-4 p-10 ">
        {filteredLogs.length > 0 &&
          filteredLogs.map((oe) => {
            console.log(oe);
            const id = ethers.BigNumber.from(oe.id).toString();
            return (
              <div className="card card-bordered ">
                <div className="width-full  justify-center items-center">
                  {/* <img
                    src={oe.image}
                    // style={{ border: '1px solid orange', width: '100px', display: 'flex', flex: 1 }}
                    className="border-4 border-orange-400 ml-30"
                  /> */}
                  <div className=" mt-10 flex justify-center">
                    <img src={oe.image} className="object-cover h-28 w-46" />
                  </div>
                </div>

                <div className="card-body flex flex-1">
                  <h2 className="card-title">{oe.name}</h2>

                  <div className="card-actions flex flex-row items-center justify-center">
                    <button onClick={() => startBurn(id)} className="btn btn-xs">
                      Add to fire 🔥
                    </button>
                    {/* <button onClick={() => getBurnTime(id)} className="btn btn-xs">
                      Get Burn Time ⏰
                    </button> */}
                  </div>
                </div>
              </div>
            );
          })}
      </div>
    </div>
  );
};

// <div className="items-center justify-center flex-1 ">
//   <div className="  rounded-lg overflow-hidden shadow-lg flex items-center justify-center  h-60  pt-10">
//     <img src={oe.image} width={100} />
//   </div>
//   <div className=" mt-5">
//     <button className="btn btn-accent">🔥 Set Ablaze 🔥</button>
//   </div>
// </div>
