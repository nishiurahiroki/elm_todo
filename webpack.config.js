const path = require("path");
const webpack = require("webpack");
const merge = require("webpack-merge");
const elmMinify = require("elm-minify");

const HTMLWebpackPlugin = require("html-webpack-plugin");

module.exports = {
    mode: 'development',
    entry: "./src/index.js",
    output: {
        path: path.join(__dirname, "dist"),
        filename: 'bundle.js'
    },
    plugins: [
        new HTMLWebpackPlugin({
            template: "./template/index.html",
            inject: "body"
        }),
        new webpack.NamedModulesPlugin(),
        new webpack.NoEmitOnErrorsPlugin()
    ],
    resolve: {
        modules: [path.join(__dirname, "src"), "node_modules"],
        extensions: [".js", ".elm"]
    },
    module: {
        rules: [
            {
                test: /\.js$/,
                exclude: /node_modules/,
                use: {
                    loader: "babel-loader"
                }
            },
            {
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                use: [
                    { loader: "elm-hot-webpack-loader" },
                    {
                      loader: "elm-webpack-loader",
                      options: {
                          debug: true,
                          forceWatch: true
                      }
                    }
                ]
            }
        ]
    },
    devServer: {
        inline: true,
        stats: "errors-only",
        host: '0.0.0.0',
        disableHostCheck: true,
        historyApiFallback: true,
        before(app) {
            app.get("/test", function(req, res) {
                res.json({ result: "OK" });
            });
        }
    }
};