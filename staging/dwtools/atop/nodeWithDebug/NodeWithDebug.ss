#! /usr/bin/env node

if( typeof module !== "undefined" )
{
  require( 'wTools' );
  require( 'wPathFundamentals' );
  require( 'wConsequence' );
  require( 'wFiles' );

  // var Chrome = require( './browser/Chrome.ss' );
  var Electron = require( './browser/electron/Electron.ss' );
  var Node = require( './node/Node.ss' );
  var ipc = require( 'node-ipc' );
  var CDP = require('chrome-remote-interface');
  var ipcMainId = 'debugnode';

  var _ = wTools;
}

//

var shell;
var debuggerPort;
var nodeVersion;
var electron;

function debuggerInfoGet( port )
{
  var request = require( 'request' );
  var requestUrl = _.uri.str
  ({
    protocol : 'http',
    host : '127.0.0.1',
    port : port,
    localPath : 'json/list'
  });

  var result = new wConsequence();

  request( requestUrl, ( err, res, data ) =>
  {
    if( err )
    return result.error( err );

    var info = JSON.parse( data )[ 0 ];
    result.give( info );
  })

  return result;
}

//

function launch()
{
  if( !process.argv[ 2 ] )
  {
    return helpGet();
  }

  var scriptPath = process.argv[ 2 ];
  scriptPath = _.path.join( _.path.current(), scriptPath );

  if( !_.fileProvider.fileStat( scriptPath ) )
  throw _.err( 'Provided file path does not exist! ', process.argv[ 2 ] );

  _prepareLaunch()
  .ifNoErrorThen( ( preloadScriptPath ) =>
  {
    var mainNode = new Node({ preloadScriptPath : preloadScriptPath });
    mainNode.launchNode();
  })



  // var debugUrlFinded = false;
  // var onDebugReady = new wConsequence();

  // shellOptions.process.stderr.on( 'data', ( data ) =>
  // {
  //   data = data.toString();

  //   if( debugUrlFinded )
  //   return;

  //   var regexs = [ /chrome-devtools:\/\/.*/, /ws:\/\/.*/ ];
  //   for( var i = 0; i < regexs.length; i++  )
  //   {
  //     var regexp = regexs[ i ];
  //     if( regexp.test( data ) )
  //     {
  //       var url = data.match( regexp )[ 0 ];
  //       if( _.strBegins( url, 'ws://' ) )
  //       {
  //         var components =
  //         {
  //           origin : 'chrome-devtools://devtools/bundled/inspector.html',
  //           query : 'experiments=true&v8only=true'
  //         }
  //         components.query += '&ws=' + _.strRemoveBegin( url, 'ws://' );
  //         url = _.urlStr( components );
  //       }
  //       onDebugReady.give( url );
  //       debugUrlFinded = true;
  //       break;
  //     }
  //   }
  // })
}

//

function _launchElectron()
{
  _.assert( !electron );

  electron = new Electron();
  var browser = electron.launchElectron();

  process.on( 'SIGINT', () => browser.process.kill() );

  // shell.doThen( () =>  browser.close() );

  // shell.doThen( browser.launched );
}

//

function _prepareLaunch()
{
  let prepareReady = new _.Consequence();

  ipc.config.id = ipcMainId;
  ipc.config.retry= 1500;
  ipc.config.silent = 1;

  ipc.serve( ipcServeHandler );
  ipc.server.start();

  let chokidar = require('chokidar');
  let watchDir = _.fileProvider.path.nativize( _.path.join( __dirname, 'node/tmp', '' + process.pid ) );
  let preloadFilePathSrc = _.path.join( __dirname, 'node/Preload.ss' );
  let preloadFilePathDst = _.path.join( watchDir, 'Preload.ss' );

  _.fileProvider.fileCopy( preloadFilePathDst, preloadFilePathSrc );

  process.on( 'exit', () => _.fileProvider.filesDelete( watchDir ) );

  let watcher;
  let nodes = {};

  process.on( 'SIGINT', () =>
  {
    if( watcher )
    watcher.close();
    ipc.server.stop()
  });

  _launchElectron();

  let electronSocket;

  ipc.server.on( 'socket.disconnected', ( socket ) =>
  {
    electronSocket = null;
    _.fileProvider.fileWrite( preloadFilePathDst, '' );
    watcher.close();
    ipc.server.stop();
  })

  ipc.server.on( 'electronReady', ( data, socket ) =>
  {
    electronSocket = socket;

    watcher = chokidar.watch( watchDir,  { ignoreInitial : true, ignored: /(^|[\/\\])\../}).on( 'all', (event, path) =>
    {

      if( event === 'add' )
      {
        var file = _.fileProvider.fileReadJson( path );
        debuggerInfoGet( file.debugPort )
        .ifNoErrorThen( ( info ) =>
        {
          let url = info.devtoolsFrontendUrl || info.devtoolsFrontendUrlCompat;
          nodes[ url ] = info;

          if( !electronSocket )
          return

          ipc.server.emit( electronSocket, 'electron.loadURL', { id : ipc.config.id, url : url } )

        })
      }
    });
  });

  //

  function ipcServeHandler()
  {
    prepareReady.give( preloadFilePathDst );
  }

  return prepareReady;
}

//

function helpGet()
{
  var help =
  {
    Usage :
    [
      'debugNode [ path ] [ args ]',
      'debugNode expects path to script file and its arguments( optional ).'
    ],
    Examples :
    [
      'debugNode sample/Sample.js',
      'debugNode sample/Sample.js arg1 arg2 arg3',
    ]
  }

  var strOptions =
  {
    levels : 3,
    wrap : 0,
    stringWrapper : '',
    multiline : 1
  };

  var help = _.toStr( help, strOptions );

  logger.log( help );

  return help;
}

//

launch();
