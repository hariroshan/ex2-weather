/*
In NativeScript, the app.ts file is the entry point to your application.
You can use this file to perform app-level initialization, but the primary
purpose of the file is to pass control to the app’s first module.
*/

import Elm from "./src/Main.elm";
import * as Geolocation from '@nativescript/geolocation';
import { CoreTypes } from "@nativescript/core"
import { start } from "elm-native-js"

const config = {
  elmModule: Elm,
  elmModuleName: "Main",
  initPorts: (ports: any) => {
    ports.getCurrentLocation.subscribe(async _ => {
      await Geolocation.enableLocationRequest()
      const location =
        await Geolocation.getCurrentLocation(
          {
            desiredAccuracy: CoreTypes.Accuracy.high,
            maximumAge: 5000,
            timeout: 20000
          }
        )
      ports.gotCurrentLocation.send(location)
    })
  }
}

start(config)

/*
Do not place any code after the application has been started as it will not
be executed on iOS.
*/
