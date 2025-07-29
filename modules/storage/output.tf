output "sample_txt_url" {
  description = "URL of the sample.txt blob"
  value = azurerm_storage_blob.sample.url
}