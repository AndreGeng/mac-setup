hs.usb.watcher.new(function(dataTable)
  if dataTable['vendorID'] == 1241 and dataTable['productID'] == 521 then
    if dataTable['eventType'] == 'added' then
      hs.execute('kess -p 1', true)
    elseif dataTable['eventType'] == 'removed' then
      hs.execute('kess', true)
    end
  end

end):start()
print(hs.execute('kess'))
