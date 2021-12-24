import { useContractLoader } from 'eth-hooks';
import { useEthersContext } from 'eth-hooks/context';
import { ethers } from 'ethers';
import { json } from 'node:stream/consumers';
import React, { useEffect, useState } from 'react';
import { Fireplace as FireplaceType } from '~~/generated/contract-types';
import { useAppContracts } from '../main/hooks/useAppContracts';

interface Props {}

const Fireplace = (props: Props) => {
  const FireplaceContract = 'Fireplace';
  const ethersContext = useEthersContext();
  const [allLogs, setAllLogs] = useState([]);
  const appContractConfig = useAppContracts();

  const readContracts = useContractLoader(appContractConfig);

  const FireRead = readContracts[FireplaceContract] as FireplaceType;

  const fetchAllLogs = async () => {
    try {
      const logs = await FireRead.numberMinted();
      const numLogs = ethers.BigNumber.from(logs);
      // console.log(numLogs.toNumber());
      setAllLogs([]);
      for (var i = 0; i < numLogs.toNumber(); i++) {
        const tokenURI = await FireRead.renderTokenById(i);
        setAllLogs((prev) => [...prev, tokenURI]);
        // console.log(allLogs);
      }
      // setAllLogs(logs);
      // logs.map((log) => {
      //   console.log(ethers.BigNumber.from(log).toString());
      // });
      // setAllLogs(logs);
    } catch (e) {
      console.log('Fetch all logs failed', e);
    }
  };

  useEffect(() => {
    fetchAllLogs();
  }, []);

  return (
    <div>
      <button onClick={fetchAllLogs}>Fireplace 🔥</button>

      <div>
        {allLogs.map((log, index) => {
          const EL = React.createElement(log);
          return <div className=" mt-10 flex justify-center">{log}</div>;
        })}
      </div>
    </div>
  );
};

export default Fireplace;
