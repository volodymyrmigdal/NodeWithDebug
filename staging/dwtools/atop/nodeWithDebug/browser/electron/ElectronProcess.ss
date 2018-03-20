( function _ElectronProcess_ss_() {

  'use strict';

  if( typeof module !== 'undefined' )
  {

    require( 'wTools' );
    require( 'wConsequence' );
    var electron = require( 'electron' );

  }

  var _ = wTools;

  var app = electron.app;
  var BrowserWindow = electron.BrowserWindow;

  var url = _.appArgs().scriptString;
  var window;

  function windowInit( )
  {
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

    window = new BrowserWindow( o );

    window.loadURL( url );

    // window.webContents.openDevTools();

    function executeJs( script )
    {
      return _.Consequence.from( window.webContents.executeJavaScript( script,true ) )
    }

    function waitForDebuggerPaused()
    {
      var checkPause = 'window.Sources ? window.Sources.SourcesPanel.instance()._paused : false';
      var unPause = 'window.Sources.SourcesPanel.instance()._togglePause()';

      console.log( 'Check for pause' );

      var con = executeJs( checkPause )
      con.doThen( ( err, got ) =>
      {
        if( got === true )
        {
          clearInterval( interval );
          return executeJs( unPause );
        }
      })
    }

    var e = /^v(\d+).(\d+).(\d+)/.exec( process.version );
    var nodeVersion =
    {
      major : Number.parseFloat( e[ 1 ] ),
      minor : Number.parseFloat( e[ 2 ] )
    }

    if( nodeVersion.major >= 8 )
    var interval = setInterval( waitForDebuggerPaused,100 );

    window.on( 'closed', function ()
    {
      window = null;
    })

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