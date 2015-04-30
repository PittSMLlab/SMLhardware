function filteredData = eff_filter(newData,oldFilteredData)

filteredData = .01*newData + .99*oldFilteredData;