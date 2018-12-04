function FA = postprocflats(FLATS,FA,fun)

% postprocess flat terrain for visualization purpose
%
% Syntax
%
%     Ap = postprocflats(FLATS,A,fun)
%
% Description
%
%     Sometimes it may be nice for visualizations to manipulate the flow 
%     accumulation raster so that flat areas such as lakes have constant
%     values instead drainage patterns returned by flow direction.
%     postprocsinks assigns equal values to each connected, flat area using
%     a user-defined function.
%
% Input
%
%     FLATS     logical grid  indicating flats (as returned by the function
%               identifyflats) (class: GRIDobj)
%     A         flow accumulation array (class: GRIDobj)
%     fun       scalar, string or function handle of a function that takes 
%               a vector and returns a scalar such as min, max, median, .
%               mean etc (default = @max). To assign the same value to each
%               flat, use following syntax: A2 = postprocflats(I,A,100000);
% 
% Output
%
%     Ap        postprocessed flow accumulation grid (class: GRIDobj)
%
% Example
%
%     DEM = GRIDobj('srtm_bigtujunga30m_utm11.tif');
%     FD = FLOWobj(DEM,'preprocess','c');
%     A  = flowacc(FD);
%     FA = postprocflats(I,A,@mean);
%     imageschs(DEM,FA)
%
% See also: IDENTIFYFLATS, FUNCTION_HANDLE
%
% Author: Wolfgang Schwanghart (w.schwanghart[at]geo.uni-potsdam.de)
% Date: 6. February, 2013


% check if GRIDs are aligned
validatealignment(FA,FLATS);
% extract values for further processing
flats = FLATS.Z;
A     = FA.Z;

% check input arguments
if ~isa(flats, 'logical')
    flats = flats>0 & ~isnan(flats);
end

if nargin==3
    
    if isa(fun, 'char');
        fun   = str2func(['@(x)' fun '(x)']);
    end
    if isa(fun, 'numeric');
        fun   = str2func(['@(x)' num2str(fun)]);
    end
    
else
    fun   = @max;
end

% find connected components
CC    = bwconncomp(flats,8);
% extract values in A
cA  = cellfun(@(x) A(x),CC.PixelIdxList,'UniformOutput',false);

% compute new values
try
    val = cell2mat(cellfun(fun,cA,'UniformOutput',false));
catch %#ok
    error('the function must take a vector and return a scalar')
end


% and write them in A
for r = 1:numel(CC.PixelIdxList);
    A(CC.PixelIdxList{r}) = val(r);
end

% write output to FA
FA.Z = A;