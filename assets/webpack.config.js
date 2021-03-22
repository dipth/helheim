
const webpack = require('webpack');
const path = require('path');
const glob = require('glob');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const TerserPlugin = require('terser-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = (env, options) => ({
  optimization: {
    minimizer: [
      new TerserPlugin({ cache: true, parallel: true, sourceMap: false }),
      new OptimizeCSSAssetsPlugin({})
    ]
  },
  entry: {
    './js/app.js': glob.sync('./vendor/**/*.js').concat(['./js/app.js'])
  },
  output: {
    filename: 'app.js',
    path: path.resolve(__dirname, '../priv/static/js')
  },
  module: {
    rules: [
      {
        test: require.resolve('jquery'),
        use: [{
            loader: 'expose-loader',
            options: 'jQuery'
        },{
            loader: 'expose-loader',
            options: '$'
        }]
      },
      {
        test: require.resolve('tether'),
        use: [{
            loader: 'expose-loader',
            options: 'Tether'
        }]
      },
      {
        test: require.resolve('pace'),
        use: [{
            loader: 'expose-loader',
            options: 'pace'
        }]
      },
      {
        test: require.resolve('dropzone'),
        use: [{
            loader: 'expose-loader',
            options: 'Dropzone'
        }]
      },
      {
        test: require.resolve('tom-select'),
        use: [{
            loader: 'expose-loader',
            options: 'TomSelect'
        }]
      },
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader'
        }
      },
      {
        test: /\.scss$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader', 'postcss-loader', 'sass-loader']
      }
    ]
  },
  plugins: [
    new MiniCssExtractPlugin({ filename: '../css/app.css' }),
    new CopyWebpackPlugin([{ from: 'static/', to: '../' }]),
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
      'window.$': 'jquery',
      'window.jQuery': 'jquery',
      Tether: 'tether',
      "window.Tether": 'tether',
      pace: 'pace',
      "window.pace": 'pace',
      IntlPolyfill: 'intl',
      Favico: 'favico.js',
      dragula: 'dragula',
      Dropzone: 'dropzone',
      TomSelect: 'tom-select'
    })
  ],
  externals: {
    //"pace": "pace"
  }
});
