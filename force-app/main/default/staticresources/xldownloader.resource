var createXmlSpreadSheet = (function() {
    var uri = 'data:application/vnd.ms-excel;base64,'
    var tmplWorkbookXML = '<?xml version="1.0" encoding="UTF-8"?>\r\n'
      + '<?mso-application progid="Excel.Sheet"?>\r\n'
      + '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">'
      + '<DocumentProperties xmlns="urn:schemas-microsoft-com:office:office">\r\n'
      + '<Created>{created}</Created>\r\n'
      + '</DocumentProperties>\r\n'
      + '<Styles>\r\n'
      + '<Style ss:ID="Currency"><NumberFormat ss:Format="Currency"></NumberFormat></Style>\r\n'
      + '<Style ss:ID="Date"><NumberFormat ss:Format="Medium Date"></NumberFormat></Style>\r\n'
      + '{styles}'
      + '</Styles>\r\n' 
      + '{worksheets}'
      + '</Workbook>'
    var tmplWorksheetXML = '<Worksheet ss:Name="{nameWS}">\r\n<Table>\r\n{rows}</Table>\r\n</Worksheet>'
    var tmplCellXML = '<Cell{index}{attributeStyleID}{attributeFormula}{merge}>{data}</Cell>'
    var tmplDataXML = '<Data ss:Type="{type}">{value}</Data>';
    var styleClasses = {};
    var styleId = 0;
    var cellStyles = '';
    var columnIndex = 1;
    var rowSpanRange = [];

    return function(tables, wsnames, wbname, appname) {
      var ctx = '';
      var dtx = ''
      var workbookXML = '';
      var worksheetsXML = '';
      var rowsXML = '';
      var dataStyle = null;
      styleClasses = {};
      styleId = 0;
      cellStyles = '';
      columnIndex = 1;
      rowSpanRange = [];
      
      //add default(sheet) styles to cellStyles
      createDefaultStyle();
      
      //table level loop
      for (var i = 0; i < tables.length; i++) {
      
        if(!tables[i].nodeType){
            tables[i] = document.getElementById(tables[i]);
        }
        rowSpanRange = [];
        dataStyle = null;
        // add column option(height) to row template string
        rowsXML += getColumnOption(tables[i].rows[0]);

        for (var j = 0; j < tables[i].rows.length; j++) {

          rowsXML += getRowOption(tables[i].rows[j].cells[0]);
          columnIndex = 1;

          for (var k = 0; k < tables[i].rows[j].cells.length; k++) {
            var element = $(tables[i].rows[j].cells[k]);
            var cellOption = getCellOption(element, j);
            createRowspanRange(j, cellOption);
            var cellIndex = getCellIndex(cellOption);
            incrementColumnIndex(cellOption.colspan);
            
            if(cellIndex < 0){
                continue;
            }
            
            dataStyle = createStyles(element);
            
            var mergeOption = getMergeOption(cellOption);
            
            var dataType = tables[i].rows[j].cells[k].getAttribute("data-type");
            var dataValue = getDataValue(element)
            var dataFormula = tables[i].rows[j].cells[k].getAttribute("data-formula");
            dataFormula = (dataFormula)?dataFormula:(appname=='Calc' && dataType=='DateTime')?dataValue:null;
            
            dtx = '';
            if(dataValue){
                var valueType = (dataType=='Number' || dataType=='DateTime' || dataType=='Boolean' || dataType=='Error')?dataType:'String'
                dtx = format(tmplDataXML, { type: valueType, value: dataValue }, true);
            }
                        
            ctx = {  attributeStyleID: dataStyle? ' ss:StyleID="' + dataStyle + '"' : ''
                   , attributeFormula: (dataFormula)?' ss:Formula="'+dataFormula+'"':''
                   , merge: mergeOption? mergeOption : ''
                   , index: cellIndex? ' ss:Index="' + cellIndex + '"' : ''
                   , data: dtx? dtx : ''
                  };
            rowsXML += format(tmplCellXML, ctx);
          }
          rowsXML += '</Row>\r\n'
        }

        ctx = {rows: rowsXML, nameWS: wsnames[i] || 'Sheet' + i};
        worksheetsXML += format(tmplWorksheetXML, ctx);
        rowsXML = "";
      }

      ctx = {created: (new Date()).getTime(), worksheets: worksheetsXML, styles: cellStyles};
      workbookXML = format(tmplWorkbookXML, ctx);

      var link = {  href: uri + base64(workbookXML),
                    download: wbname || 'Workbook.xls',
                    target: '_blank'
                 }
      return link;
    }
    
    function base64(s) {
        return window.btoa(unescape(encodeURIComponent(s))) 
    }

    function format(s, c, withoutBreak) {
        if(withoutBreak){
            return s.replace(/{(\w+)}/g, function(m, p) { return c[p]; });
        }else{
            return s.replace(/{(\w+)}/g, function(m, p) { return c[p]; }) + "\r\n";
        }
    }
    
    function getDataValue(s){
        var dataValue = s.attr("data-value");
        dataValue = dataValue? dataValue : s.html();
        var br = dataValue.includes("<br>")? "<br>" : null;
        br = (!br && dataValue.includes("<br/>"))? "<br/>" : br;
        if(br){
            dataValue = dataValue.replace(new RegExp(br,"g"), "&#10;");
        }
        
        dataValue = dataValue.replace(/\r\n/g, "&#10;").replace(/\r/g, "&#10;").replace(/\n/g, "&#10;");
        return dataValue.replace(/\<.*\>/g, "").replace(/\<\/.*\>/g, "");
    }
    
    function createDefaultStyle(){
        cellStyles += '<Style ss:ID="Default" ss:Name="Normal">\r\n'
                    + '<Alignment ss:Vertical="Center"/>\r\n'
                    + '<Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/>\r\n'
                    + '</Style>\r\n';
    }
    
    function createStyles(s){
        var styleClass = s.attr('class');
        if(styleClasses[styleClass]){
            return styleClasses[styleClass];
        }
        
        styleId += 1;
        if(styleClass){
            styleClasses[styleClass] = styleId;
        }
        
        var temp = '<Style ss:ID="{id}">\r\n{style}</Style>';
        var styles = '';
        styles += getBorder(s)
        styles += getBackgroundColor(s);

        if(s.html() != null && s.html() != ''){
            styles += getFont(s);
            styles += getAlignment(s);
        }

        if(styles != ''){
            cellStyles += format(temp, {id: styleId, style: styles});
            return styleId;
        }else{
            return null;
        }
    }

    function getCellOption(s, rowIndex){
        var options = {
                        colspan : s.prop('colspan'),
                        mergeAcross : s.prop('colspan') - 1,
                        rowspan : s.prop('rowspan'),
                        mergeDown : s.prop('rowspan') - 1,
                        columnIndex : columnIndex,
                        rowIndex : rowIndex
                       };
        
        return options;
    }
    
    function incrementColumnIndex(colspan){
        if(colspan > 1){
            columnIndex += colspan;
        }else{
            columnIndex += 1;
        }        
    }

    function createRowspanRange(rowIndex, cellOption){
        if(cellOption.rowspan > 1){
            for(var i = 1; i <= cellOption.mergeDown; i++){
                var range = { rowIndex: rowIndex + i,
                              startCol : cellOption.columnIndex,
                              endCol : cellOption.columnIndex + cellOption.colspan,
                              colspan : cellOption.colspan
                            };
                                             
                rowSpanRange.push(range);
            }
        }
    }
    
    function getMergeOption(cellOption){
        var temp = '';
        if(cellOption.colspan > 1){
            temp += ' ss:MergeAcross="' + cellOption.mergeAcross + '"';
        }
        
        if(cellOption.rowspan > 1){
            temp += ' ss:MergeDown="' + cellOption.mergeDown + '"';
        }
        
        return temp;
    }
    
    function withinMergedRow(element){
        if(element.rowIndex == this){
            return true;
        }else{
            return false;
        }
    }
    
    function getCellIndex(cellOption){
        if(!rowSpanRange.some(withinMergedRow, cellOption.rowIndex))
            return null;
        
        for(var span of rowSpanRange){
            if(cellOption.columnIndex >= span.startCol && cellOption.columnIndex <= span.endCol){
                incrementColumnIndex(span.colspan);
                cellOption.columnIndex = columnIndex;
            }
        }
        
        for(var span of rowSpanRange){
            if(cellOption.columnIndex >= span.endCol){
                rowSpanRange.shift();
                return cellOption.columnIndex;
            }
        }
        
        return null;
    }

    function getColumnOption(firstRow){
        var columns = '';
        var column = '<Column ss:Index="{index}" ss:AutoFitWidth="0" ss:Width="{width}"/>';
        for (var i = 0; i < firstRow.cells.length; i++){
            columns += format(column, {index: i + 1, width: getSize($(firstRow.cells[i]).css('width'))});
        }
        return columns;
    }
    
    function getRowOption(firstCell){
        var temp = '<Row ss:AutoFitHeight="0" ss:Height="{height}">'
        return format(temp, {height: getSize($(firstCell).css('height'))});
    }
    
    function isZeroBorder(b){
        return b == '0px';
    }
    
    function getSize(s){
        return 3/4 * s.replace(/px/g, '');
    }
    
    function capitalizeFirstLetter(string) {
        return string.charAt(0).toUpperCase() + string.slice(1);
    }
    
    function replaceStyleName(name){
        return name.replace(/solid/g, 'Continuous')
        .replace(/double/g, 'Double')
        .replace(/dash/g, 'Dash')
        .replace(/none/g, 'Continuous')
        .replace(/inset/g, 'Continuous');
    }
    
    function getBorder(s){
        var temp = '<Borders>{border}</Borders>';
        var borders = '';
        var border ='<Border ss:Position="{position}" ss:LineStyle="{style}" ss:Weight="{width}" ss:Color="{color}"/>';
        var css = s.css(['border-style', 'border-width', 'border-color']);

        var position = ['Top','Right','Bottom','Left'];
        var width = css['border-width'].split(' ');
        if(width.every(isZeroBorder)) return '';
        width = width.map(function(a){return a.replace(/px/g, '');});
        width = getBorderStyles(width);

        var style = css['border-style'].split(' ');
        style = style.map(replaceStyleName);
        style = getBorderStyles(style);
        
        var color = css['border-color'];
        color = color.replace(/\,\s/g, '@').split(' ').map(function(a){return a.replace("@",", ");}).map(getColor);
        color = getBorderStyles(color);

        for(var i = 0; i < position.length; i++){
            if(width[i] > 0){
                borders += format(border, {position: position[i], style: style[i], width: width[i], color:color[i]});
            }
        }
                
        return format(temp, {border: borders});
    }

    function getBorderStyles(style){
       //if size = 1 then top/btn/left/right
       //if size = 2 then top/btn & left/right
       //if size = 3 then top & left/right & bottom
       //if size = 4 then top & right & bottom & left
        switch (style.length){
            case 1:
                return [style[0], style[0], style[0], style[0]];
            case 2:
                return [style[0], style[1], style[0], style[1]];
            case 3:
                return [style[0], style[1], style[2], style[1]];
            case 4:
                return [style[0], style[1], style[2], style[3]];
        }
        return '';
    }
    
    function getFont(s){
        var temp = '<Font ss:FontName="{family}" ss:Size="{size}" ss:Color="{color}" ss:Bold="{bold}"/>';
        var css = s.css(['color','font-weight', 'font-family', 'font-size']);
        var color = getColor(css['color']);
        var weight = css['font-weight'];
        var bold = 0;
        if(weight >= 700){
            bold = 1;
        }
        var family = css['font-family'].replace(/\"/g, '');
        var size = getSize(css['font-size']);
        return format(temp, {family: family, size: size, color: color, bold: bold});
    }
    
    function getAlignment(s){
        var temp = '<Alignment ss:Horizontal="{halign}" ss:Vertical="{valign}"{wrap}/>';
        var halign = capitalizeFirstLetter(s.css('text-align')).replace(/Middle/g, 'Center');
        var valign = capitalizeFirstLetter(s.css('vertical-align')).replace(/Middle/g, 'Center');
        var wrap = s.css('overflow-wrap');
        if(wrap == 'normal')
            wrap = '';
        return format(temp, {halign: halign, valign: valign, wrap: wrap? ' ss:WrapText="1"' : ''});
    }
    
    function getBackgroundColor(s){
        var temp = '<Interior ss:Color="{color}" ss:Pattern="Solid"/>'
        var color = getColor(s.css('background-color'));
        if(color == "#00000000")
            return '';
        
        return format(temp, {color: color});
    }
    
    function getColor(bg){
      if(bg == null){return null;}
      return "#" + bg.match(/\d+/g).map(function(a){return ("0" + parseInt(a).toString(16)).slice(-2)}).join("");
    }
    
  })();
  