classdef Map < handle
    properties
        urls = struct(...
            'osm', 'http://a.tile.openstreetmap.org', ...
            'hot', 'http://a.tile.openstreetmap.fr/hot', ...
            'ocm', 'http://a.tile.opencyclemap.org/cycle', ...
            'opm', 'http://www.openptmap.org/tiles', ...
            'landscape', 'http://a.tile.thunderforest.com/landscape', ...
            'outdoors', 'http://a.tile.thunderforest.com/outdoors');
        ax
        coords
        style = 'osm'
    end

    properties (Dependent)
        zoomLevel
    end

    methods
        function obj = Map(ax, coords, style)
            obj.ax = ax;
            narginchk(2, 3);
            obj.coords = coords;
            if nargin == 3
                obj.style = style;
            end
            obj.draw();
        end

        function draw(obj)
            [minX, maxX, minY, maxY] = obj.tileIndices();

            % set figure to the correct aspect ratio
            degHeight = (obj.coords.maxLat-obj.coords.minLat);
            degWidth = (obj.coords.maxLon-obj.coords.minLon);
            pixelTileWidth = 256*(maxX-minX+1); % 256 px per tile
            pixelTileHeight = 256*(maxY-minY+1); % 256 px per tile
            degTileWidth = abs(obj.x2lon(maxX+1) - ...
                               obj.x2lon(minX));
            degTileHeight = abs(obj.y2lat(maxY+1) - ...
                                obj.y2lat(minY));
            pixelWidth = pixelTileWidth/degTileWidth*degWidth;
            pixelHeight = pixelTileHeight/degTileHeight*degHeight;
            pbaspect(obj.ax, [pixelWidth/pixelHeight, 1, 1]);

            hold(obj.ax, 'on');
            axis(obj.ax, 'xy');
            xlim(obj.ax, [obj.coords.minLon, obj.coords.maxLon]);
            ylim(obj.ax, [obj.coords.minLat, obj.coords.maxLat]);

            % download tiles
            for x=minX:maxX
                for y=minY:maxY
                    imagedata = obj.downloadTile(x, y);
                    image(obj.ax, ...
                          obj.x2lon([x, x+1]), ...
                          obj.y2lat([y, y+1]), ...
                          imagedata);
                    drawnow();
                end
            end
        end

        function zoom = get.zoomLevel(obj)
            % make sure we are at least 4 tiles high/wide
            latHeight = (obj.coords.maxLat-obj.coords.minLat);
            latZoom = ceil(log2(170.1022/latHeight));
            lonWidth = (obj.coords.maxLon-obj.coords.minLon);
            lonZoom = ceil(log2(360/lonWidth));
            zoom = max([lonZoom, latZoom])+1; % zoom in by 1
        end

        function [minX, maxX, minY, maxY] = tileIndices(obj)
            minX = obj.lon2x(obj.coords.minLon);
            maxX = obj.lon2x(obj.coords.maxLon);
            if minX > maxX
                [minX, maxX] = deal(maxX, minX);
            end

            minY = obj.lat2y(obj.coords.minLat);
            maxY = obj.lat2y(obj.coords.maxLat);
            if minY > maxY
                [minY, maxY] = deal(maxY, minY);
            end
        end

        function imagedata = downloadTile(obj, x, y)
            baseurl = obj.urls.(obj.style);
            url = sprintf('%s/%i/%d/%d.png', baseurl, obj.zoomLevel, x, y);
            [indices, cmap] = imread(url);
            imagedata = ind2rgb(indices, cmap);
        end

        function x = lon2x(obj, lon)
            x = floor(2^obj.zoomLevel * ((lon + 180) / 360));
        end

        function y = lat2y(obj, lat)
            lat = lat / 180 * pi;
            y = floor(2^obj.zoomLevel * (1 - (log(tan(lat) + sec(lat)) / pi)) / 2);
        end

        function lon = x2lon(obj, x)
            lon = x / 2^obj.zoomLevel * 360 - 180;
        end

        function lat = y2lat(obj, y)
            lat_rad = atan(sinh(pi * (1 - 2 * y / (2^obj.zoomLevel))));
            lat = lat_rad * 180 / pi;
        end
    end

end
