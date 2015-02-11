module Page.Module where

import Color
import ColorScheme as C
import Dict
import Json.Decode as Json
import Graphics.Element (..)
import Http
import List
import LocalChannel as LC
import Signal
import String
import Window

import Component.TopBar as TopBar
import Component.Module as Module
import Component.Documentation as D


port context : { user : String, name : String, version : String, versionList : List String, moduleName : String }

port title : String
port title =
    context.user ++ "/" ++ context.name ++ " " ++ context.version ++ " " ++ context.moduleName


packageUrl : String -> String
packageUrl version =
  "/packages/" ++ context.user ++ "/" ++ context.name ++ "/" ++ version


moduleNameToUrl : String -> String
moduleNameToUrl name =
  String.map (\c -> if c == '.' then '-' else c) name


documentationUrl : String
documentationUrl =
  let name = moduleNameToUrl context.moduleName
  in
      name ++ ".json"


documentation : Signal D.Documentation
documentation =
    Http.sendGet (Signal.constant documentationUrl)
      |> Signal.map handleResult


dummyDocs : D.Documentation
dummyDocs =
  D.Documentation context.moduleName "Loading documentation..." [] [] []


handleResult : Http.Response String -> D.Documentation
handleResult response =
  case response of
    Http.Success string ->
      case Json.decodeString D.documentation string of
        Ok docs -> docs
        Err msg ->
            { dummyDocs |
                comment <- "There was an error loading these docs! They may be corrupted."
            }

    _ -> dummyDocs


main : Signal Element
main =
    Signal.map2 view Window.dimensions documentation


versionChan : Signal.Channel String
versionChan =
    Signal.channel ""


port redirect : Signal String
port redirect =
  Signal.keepIf ((/=) "") "" (Signal.subscribe versionChan)
    |> Signal.map (\v -> packageUrl v ++ "/" ++ moduleNameToUrl context.moduleName)


port docsLoaded : Signal ()
port docsLoaded =
  Signal.map (always ()) documentation


view : (Int,Int) -> D.Documentation -> Element
view (windowWidth, windowHeight) docs =
  let innerWidth = min 980 windowWidth
  in
    color C.background <|
    flow down
    [ TopBar.view windowWidth
    , flow right
      [ spacer ((windowWidth - innerWidth) // 2) (windowHeight - TopBar.topBarHeight)
      , Module.view (LC.create identity versionChan) innerWidth context.user context.name context.version context.versionList docs
      ]
    ]
