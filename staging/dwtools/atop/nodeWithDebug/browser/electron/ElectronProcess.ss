( function _ElectronProcess_ss_() {

  'use strict';

  if( typeof module !== 'undefined' )
  {

    require( 'wTools' );

    var _ = _global_.wTools;

    _.include( 'wConsequence' );
    _.include( 'wPathFundamentals' );
    _.include( 'wStringsExtra' );
    _.include( 'wExternalFundamentals' );

    var ipc = require( 'node-ipc' );
    var ipcMainId = 'debugnode';

    var electron = require( 'electron' );
    // var CDP = require( 'chrome-remote-interface' );
  }

  var app = electron.app;
  var BrowserWindow = electron.BrowserWindow;

  var url = _.appArgs().scriptString;
  var window;

  var o =
  {
    width : 1280,
    height : 720,
    webPreferences :
    {
      nodeIntegration : true
    },
    title : 'DebugNode',
  }

  function prepareIpcConnection()
  {
    ipc.config.id = 'electron';
    ipc.config.retry= 1500;
    ipc.config.silent = 1;

    var debugNodeIpc;

    ipc.connectTo( ipcMainId, connectToDebugNodeHanler );

    function connectToDebugNodeHanler()
    {
      debugNodeIpc = ipc.of[ ipcMainId ];
      debugNodeIpc.on( 'connect', onConnectToDebugNodeHandler );
      debugNodeIpc.on( 'electron.loadURL', onElectronLoadURL );
    }

    function onConnectToDebugNodeHandler()
    {
      debugNodeIpc.emit( 'electronReady', { id : ipc.config.id, message : true } )
    }

    function onElectronLoadURL( data )
    {
      var togglePause = 'window.Sources.SourcesPanel.instance()._togglePause()';

      let info =
      {
        id : ipc.config.id,
        url : data.url,
        main : 0,
        child : 0
      }

      if( !window )
      {
        window = new BrowserWindow( o );

        info.main = 1;

        _.assert( window instanceof BrowserWindow );
        window.loadURL( data.url );

        // window.webContents.openDevTools();

        // let ws = 'ws://' + _.strIsolateBeginOrNone( data.url, 'ws=' )[ 2 ]

        window.on( 'closed', function ()
        {
          ipc.disconnect( ipc.of[ ipcMainId ] );
          window = null;
        })
      }
      else
      {
        var child = new BrowserWindow( _.mapExtend( null, o, { parent : window } ) );
        info.child = 1;
        child.loadURL( data.url );

        child.on( 'closed', function ()
        {
          child = null;
        })

        child.show();
      }
    }
  }

  //

  function windowInit( )
  {
    prepareIpcConnection();
  }

  app.on( 'ready', windowInit );
  app.on( 'browser-window-created', function (e, window )
  {
    window.setMenu( null );
  })

  app.on( 'window-all-closed', function ()
  {
    app.quit();
  });

  app.on( 'activate', function ()
  {
    if ( window === null && !self.headless )
    windowInit();
  })
})();