# demo-plumber-store-weather

A demo of how to use [Plumber](https://www.rplumber.io/index.html) to create APIs on RStudio Connect.

- Code: <https://github.com/tnederlof/demo-plumber-store-weather>
- Deployment: <https://colorado.rstudio.com/rsc/demo-plumber-penguins/>

<https://colorado.rstudio.com/rsc/store-weather-api/>

## Usage

```bash
curl -X POST "https://colorado.rstudio.com/rsc/store-weather-api/weather?storeid=7864-83541"
```

## Deployment

### Git-backed

After making any code changes run the following:

```r
rsconnect::writeManifest()
```

RStudio Connect will then automatically redeploy the app.

### Programatic

You can also deploy the app using the `rsconnect` api:

```r
rsconnect::deployAPI(
  api = ".",
  appFiles = c("plumber.R"),
  appTitle = "Starbucks Store Weather API"
)
```