{-# LANGUAGE OverloadedStrings #-}
module Main where

import Prelude (head)
import BasePrelude
import qualified Data.Text.IO as T
import Data.Text
import Docker.Client
import Docker.Client.Http
import System.IO

containersOrErr :: Either DockerError [Container] -> [Container]
containersOrErr (Left err)   = trace (show err) []
containersOrErr (Right cs) = cs

type Host = Text
type IP = Text

toHostsFile :: (Host, IP) -> Text
toHostsFile (host, ip) = Data.Text.concat [ip, "    ", host]

containerHost :: Container -> Maybe Host
containerHost = host . labels
  where
    labels :: Container -> [Label]
    labels = BasePrelude.filter fLabel . containerLabels
    host :: [Label] -> Maybe Host
    host [] = Nothing
    host [(Label _ value)] = Just value

fLabel :: Label -> Bool
fLabel (Label key value) = "dns.host" == key
  
containerIP :: [Network] -> IP
containerIP []     = "0.0.0.0"
containerIP ((Network mode settings):ns) = networkOptionsIpAddress settings

maybeHostIP :: Container -> Maybe (Host, IP)
maybeHostIP c = if host == Nothing then Nothing else combine host ip
           where
             combine Nothing _ = Nothing
             combine (Just hostname) i = Just (hostname, i)
             host = containerHost c
             ip = containerIP $ containerNetworks c

processContainer :: Either DockerError [Container] -> [Text]
processContainer = fmap toHostsFile . catMaybes . (fmap maybeHostIP) . containersOrErr


writeHosts :: [Text] -> Handle -> IO ()
writeHosts lines file = do
  T.hPutStrLn file . Data.Text.strip . Data.Text.unlines $ lines

main :: IO ()
main = do
  h <- unixHttpHandler "/var/run/docker.sock"
  print "Listing containers"
  dockerCmd <- return $ fmap processContainer $ listContainers defaultListOpts
  containers <- runDockerT (defaultClientOpts, h) $ dockerCmd
  withFile "./hosts" ReadWriteMode $ writeHosts containers
