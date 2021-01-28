class Retailer::WordPressController < Retailer::BaseController
  before_action :connet_api_dicatalog, only: [:index]
  def index
    gettoken = "Bearer #{@response}"
    url = "http://172.16.0.149:8899/api/v1.0/item/GetList"
    params = {QueryParam: {
                  PageNumber: 1,
                  PageSize: 20,
                  OrderBy: "Id",
                  OrderType: "DESC"
                },
                VendorId: 20449,
                HubId: 18355}
    headers = {Authorization: gettoken, content_type: :json}
    request = RestClient.post(url,params.to_json,headers)
    response = JSON.parse(request)
    @products = response['Data']
  end

  private
  def connet_api_dicatalog
    url = URI("http://172.16.0.149:8899/api/v1/user/generateToken?ClientId=9A46AF7E-CA54-4B0D-8934-2A373DAAE77E&ApiKey=d195gZZOwZ0D8WxQE6X63PpXVF6lL4fjU/8aHxgXHhg=")

    http = Net::HTTP.new(url.host, url.port);
    request = Net::HTTP::Get.new(url)

    response = http.request(request)
    response = JSON.parse(response.read_body)
    @response = response['Message']
  end
end

# https://github.com/josefzacek/infinite-scrolling
# https://www.sitepoint.com/infinite-scrolling-rails-basics/
# http://geekhmer.github.io/blog/2015/02/12/ruby-on-rails-with-endless-scrolling/
# https://github.com/gorails-screencasts/infinite-scroll-stimulus-js



