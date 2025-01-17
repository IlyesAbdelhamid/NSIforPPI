function tm = compute_topological_measures(x, request, iters)

% code to perform a wide analysis on network topological measures.
%
% Authors:
% - main code: Alessandro Muscoloni, 2017-05-12
% - support functions: either implemented or taken from other sources,
%   indicated at the beginning of the function.
%
% Reference:
% "Can local-community-paradigm and epitopological learning enhance
% our understanding of how local brain connectivity is able to process,
% learn and memorize chronic pain?"
% Vaibhav Narula et al., Applied Network Science, 2017, 2:28
% https://doi.org/10.1007/s41109-017-0048-x
%
% for each measure, the support function reports the original source,
% please cite the proper reference if you use it.
%
% Released under MIT License
% Copyright (c) 2017 A. Muscoloni, C. V. Cannistraci

%%% INPUT
% x - adjacency matrix of the network
%     the network is considered unweighted, undirected and zero-diagonal
%
% request - cell array with the names of the required measures among:
%           N - nodes
%           E - edges
%           avgdeg - average degree
%           density - density
%           clustering - clustering coefficient
%           char_path - characteristic path length
%           efficiency_glob - global efficiency
%           efficiency_loc - local efficiency
%           closeness - closeness centrality
%           EBC - edge betweenness centrality
%           BC - node betweenness centrality
%           radiality - radiality
%           LCP_corr - Local Community Paradigm correlation
%           assortativity - assortativity
%           modularity - modularity
%           struct_cons - structural consistency
%           powerlaw_p - pvalue for power-lawness
%           powerlaw_gamma - fitted exponent of power-law degree distribution
%           smallworld_omega - small worldness omega
%           smallworld_sigma - small worldness sigma
%           smallworld_omega_eff - small worldness omega (efficiency)
%           smallworld_sigma_eff - small worldness sigma (efficiency)
%
%           NB: if the input is not provided or an empty array [] is given,
%               all the measures are computed
%
% iters - structure containing for the stochastic measures
%         the number of iterations.
%         if the input is not provided, the default values are:
%         iters.modularity = 100;
%         iters.struct_cons = 100;
%         iters.powerlaw_p = 1000;
%         iters.x_rand = 10;
%         iters.x_latt = 10;

%%% OUTPUT
% tm - structure array containing the topological measures.
%      the names of the structure fields correspond to the names
%      in the input variable "request"

narginchk(1,3);

% check input matrix and make it unweighted, undirected and zero-diagonal
validateattributes(x, {'numeric'}, {'square','finite','nonnegative'});
x = x > 0;
x = double(max(x,x'));
x(speye(size(x))==1) = 0;

measures_all = {'N', 'E', 'avgdeg', 'density', 'clustering', ...
    'char_path', 'efficiency_glob', 'efficiency_loc', 'closeness', ...
    'EBC', 'BC', 'radiality', 'LCPcorr', 'assortativity', ...
    'modularity', 'struct_cons', 'powerlaw_p', 'powerlaw_gamma', ...
    'smallworld_omega', 'smallworld_sigma', ...
    'smallworld_omega_eff', 'smallworld_sigma_eff'};

% check request
if ~exist('request', 'var') || isempty(request)
    request = measures_all;
else
    validateattributes(request, {'cell'}, {});
    for j = 1:length(request)
        if ~any(strcmp(request{j}, measures_all))
            error(['measure name ''' request{j} ''' not valid'])
        end
    end
end

% check iters
if ~exist('iters', 'var')
    iters = struct();
else
    validateattributes(iters, {'struct'}, {});
end
if ~isfield(iters, 'modularity')
    iters.modularity = 100;
else
    validateattributes(iters.modularity, {'numeric'}, {'scalar','integer','nonnegative'});
end
if ~isfield(iters, 'struct_cons')
    iters.struct_cons = 100;
else
    validateattributes(iters.struct_cons, {'numeric'}, {'scalar','integer','nonnegative'});
end
if ~isfield(iters, 'powerlaw_p')
    iters.powerlaw_p = 1000;
else
    validateattributes(iters.powerlaw_p, {'numeric'}, {'scalar','integer','nonnegative'});
end
if ~isfield(iters, 'x_rand')
    iters.x_rand = 10;
else
    validateattributes(iters.x_rand, {'numeric'}, {'scalar','integer','nonnegative'});
end
if ~isfield(iters, 'x_latt')
    iters.x_latt = 10;
else
    validateattributes(iters.x_latt, {'numeric'}, {'scalar','integer','nonnegative'});
end

tm = struct();

for j = 1:length(request)
    
    % compute shortest paths
    if any(strcmp(request{j},{'char_path', 'efficiency_glob', 'efficiency_loc', 'closeness', 'radiality'})) && ~exist('dist','var')
        dist = graphallshortestpaths(sparse(x), 'Directed', false);
    end
    
    % compute null models for random networks
    if any(strcmp(request{j},{'smallworld_omega', 'smallworld_sigma', 'smallworld_omega_eff', 'smallworld_sigma_eff'})) ...
            && ~exist('x_rand','var')
        x_rand = cell(iters.x_rand,1);
        for i = 1:iters.x_rand
            x_rand{i} = randmio_und(x, 10);
        end
    end
    
    % compute null models for lattice networks
    if any(strcmp(request{j},{'smallworld_omega', 'smallworld_omega_eff'})) ...
            && ~exist('x_latt','var')
        x_latt = cell(iters.x_latt,1);
        for i = 1:iters.x_latt
            x_latt{i} = latmio_und(x, 10);
        end
    end
    
    switch request{j}
        
        case 'N'
            tm.N = size(x,1);
            
        case 'E'
            tm.E = sum(x(:))/2;
            
        case 'avgdeg'
            tm.avgdeg = mean(sum(x));
            
        case 'density'
            tm.density = mean(x(triu(true(size(x)),1)));
            
        case 'clustering'
            tm.clustering = mean(clustering_coef_bu(x));
            
        case 'char_path'
            tm.char_path = mean(dist(~isinf(dist) & dist>0));
            
        case 'efficiency_glob'
            if ~isfield(tm, 'efficiency_glob')
                [tm.efficiency_glob, efficiency_loc] = compute_efficiency(x, dist);
                if any(strcmp('efficiency_loc', request))
                    tm.efficiency_loc = efficiency_loc; clear efficiency_loc;
                end
            end
            
        case 'efficiency_loc'
            if ~isfield(tm, 'efficiency_loc')
                [efficiency_glob, tm.efficiency_loc] = compute_efficiency(x, dist);
                if any(strcmp('efficiency_glob', request))
                    tm.efficiency_glob = efficiency_glob; clear efficiency_glob;
                end
            end
            
        case 'closeness'
            tm.closeness = mean(closeness_centrality(dist));
            
        case 'EBC'
            if ~isfield(tm, 'EBC')
                [EBC, BC] = edge_betweenness_bin(x);
                tm.EBC = mean(EBC(x>0)); clear EBC;
                if any(strcmp('BC', request))
                    tm.BC = mean(BC); clear BC;
                end
            end
            
        case 'BC'
            if ~isfield(tm, 'BC')
                [EBC, BC] = edge_betweenness_bin(x);
                tm.BC = mean(BC); clear BC;
                if any(strcmp('EBC', request))
                    tm.EBC = mean(EBC(x>0)); clear EBC;
                end
            end
            
        case 'radiality'
            tm.radiality = mean(compute_radiality(dist));
            
        case 'LCPcorr'
            tm.LCPcorr = LCPcorr_and_LCDP(x,0);
            
        case 'assortativity'
            tm.assortativity = compute_assortativity(x);
            
        case 'modularity'
            tm.modularity = zeros(iters.modularity,1);
            for i = 1:iters.modularity
                try
                    [~, tm.modularity(i)] = modularity_und(full(x));
                catch
                    % the try-catch statement is needed to avoid the error:
                    % 'EIG did not converge' (it could occur for some iterations)
                    tm.modularity(i) = NaN;
                end
            end
            tm.modularity = nanmean(tm.modularity);
            
        case 'struct_cons'
            tm.struct_cons = zeros(iters.struct_cons,1);
            for i = 1:iters.struct_cons
                try
                    tm.struct_cons(i) = avg_structCons_carlo(double(x), 1);
                catch
                    % the try-catch statement is needed to avoid the error:
                    % 'EIG did not converge' (it could occur for some iterations)
                    tm.struct_cons(i) = NaN;
                end
            end
            tm.struct_cons = nanmean(tm.struct_cons);
            
        case 'powerlaw_p'
            if ~isfield(tm, 'powerlaw_p')
                gamma_range = 1.01:0.01:10.00;
                small_size_limit = 100;
                deg = sum(x);
                if length(deg) < small_size_limit
                    [powerlaw_gamma, xmin] = plfit(deg, 'finite', 'range', gamma_range);
                else
                    [powerlaw_gamma, xmin] = plfit(deg, 'range', gamma_range);
                end
                tm.powerlaw_p = plpva(deg, xmin, 'reps', iters.powerlaw_p, 'silent');
                if any(strcmp('powerlaw_gamma', request))
                    tm.powerlaw_gamma = powerlaw_gamma;
                end
                clear deg xmin gamma_range small_size_limit powerlaw_gamma
            end
            
        case 'powerlaw_gamma'
            if ~isfield(tm, 'powerlaw_gamma')
                gamma_range = 1.01:0.01:10.00;
                small_size_limit = 100;
                deg = sum(x);
                if length(deg) < small_size_limit
                    [tm.powerlaw_gamma, xmin] = plfit(deg, 'finite', 'range', gamma_range);
                else
                    [tm.powerlaw_gamma, xmin] = plfit(deg, 'range', gamma_range);
                end
                if any(strcmp('powerlaw_p', request))
                    tm.powerlaw_p = plpva(deg, xmin, 'reps', iters.powerlaw_p, 'silent');
                end
                clear deg xmin gamma_range small_size_limit
            end
            
        case 'smallworld_omega'
            tm.smallworld_omega = compute_smallworld_omega(x, x_rand, x_latt);
            
        case 'smallworld_sigma'
            tm.smallworld_sigma = compute_smallworld_sigma(x, x_rand);
            
        case 'smallworld_omega_eff'
            tm.smallworld_omega_eff = compute_smallworld_omega_eff(x, x_rand, x_latt);
            
        case 'smallworld_sigma_eff'
            tm.smallworld_sigma_eff = compute_smallworld_sigma_eff(x, x_rand);
            
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Clustering coefficient %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% code from the Brain Connectivity Toolbox
% https://sites.google.com/site/bctnet/
%
% please cite:
% Complex network measures of brain connectivity: Uses and interpretations.
% Rubinov M, Sporns O (2010) NeuroImage 52:1059-69.

function C=clustering_coef_bu(G)
%CLUSTERING_COEF_BU     Clustering coefficient
%
%   C = clustering_coef_bu(A);
%
%   The clustering coefficient is the fraction of triangles around a node
%   (equiv. the fraction of node�s neighbors that are neighbors of each other).
%
%   Input:      A,      binary undirected connection matrix
%
%   Output:     C,      clustering coefficient vector
%
%   Reference: Watts and Strogatz (1998) Nature 393:440-442.
%
%
%   Mika Rubinov, UNSW, 2007-2010

n=length(G);
C=zeros(n,1);

for u=1:n
    V=find(G(u,:));
    k=length(V);
    if k>=2;                %degree must be at least 2
        S=G(V,V);
        C(u)=sum(S(:))/(k^2-k);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%
%%% Efficiency %%%
%%%%%%%%%%%%%%%%%%

% code implemented by Alessandro Muscoloni
%
% Reference:
% Efficient Behavior of Small-World Networks
% Vito Latora and Massimo Marchiori (2001)
% Phys. Rev. Lett. 87, 198701

function [eff_glob, eff_loc] = compute_efficiency(x, dist)

%%% INPUT %%%
% x - adjacency matrix (unweighted and undirected)
% dist - [optional] shortest paths kernel

%%% OUTPUT %%%
% eff_glob - global efficiency
% eff_loc - local efficiency

if ~exist('dist','var')
    dist = graphallshortestpaths(sparse(x), 'Directed', false);
end
    
eff_glob = mean(1 ./ dist(dist>0));

eff_loc = zeros(length(x),1);
for i = 1:length(x)
    neigh = logical(x(i,:));
    subx = x(neigh,neigh);
    if length(subx) > 1
        dist = graphallshortestpaths(sparse(subx), 'Directed', false);
        eff_loc(i) = mean(1 ./ dist(dist>0));
    end
end
eff_loc = mean(eff_loc);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Closeness centrality %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% code implemented by Alessandro Muscoloni
%
% Reference:
% Node centrality in weighted networks: Generalizing degree and shortest paths.
% Opsahl T. et al. (2010)
%
% Generalization of the closeness centrality for disconnected graph.
% The measure for a node is computed as the sum of the inversed distances,
% rather than the inverse of the sum of the distances.

function c = closeness_centrality(dist)

dist = 1 ./ dist;
dist(isinf(dist)) = 0;
c = sum(dist);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Betweenness centrality %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% code from the Brain Connectivity Toolbox
% https://sites.google.com/site/bctnet/
%
% please cite:
% Complex network measures of brain connectivity: Uses and interpretations.
% Rubinov M, Sporns O (2010) NeuroImage 52:1059-69.

function [EBC, BC]=edge_betweenness_bin(G)
%EDGE_BETWEENNESS_BIN    Edge betweenness centrality
%
%   EBC = edge_betweenness_bin(A);
%   [EBC BC] = edge_betweenness_bin(A);
%
%   Edge betweenness centrality is the fraction of all shortest paths in
%   the network that contain a given edge. Edges with high values of
%   betweenness centrality participate in a large number of shortest paths.
%
%   Input:      A,      binary (directed/undirected) connection matrix.
%
%   Output:     EBC,    edge betweenness centrality matrix.
%               BC,     node betweenness centrality vector.
%
%   Note: Betweenness centrality may be normalised to the range [0,1] as
%   BC/[(N-1)(N-2)], where N is the number of nodes in the network.
%
%   Reference: Brandes (2001) J Math Sociol 25:163-177.
%
%
%   Mika Rubinov, UNSW/U Cambridge, 2007-2012


n=length(G);
BC=zeros(n,1);                  %vertex betweenness
EBC=zeros(n);                   %edge betweenness

for u=1:n
    D=false(1,n); D(u)=1;      	%distance from u
    NP=zeros(1,n); NP(u)=1;     %number of paths from u
    P=false(n);                 %predecessors
    Q=zeros(1,n); q=n;          %order of non-increasing distance
    
    Gu=G;
    V=u;
    while V
        Gu(:,V)=0;              %remove remaining in-edges
        for v=V
            Q(q)=v; q=q-1;
            W=find(Gu(v,:));                %neighbours of v
            for w=W
                if D(w)
                    NP(w)=NP(w)+NP(v);      %NP(u->w) sum of old and new
                    P(w,v)=1;               %v is a predecessor
                else
                    D(w)=1;
                    NP(w)=NP(v);            %NP(u->w) = NP of new path
                    P(w,v)=1;               %v is a predecessor
                end
            end
        end
        V=find(any(Gu(V,:),1));
    end
    if ~all(D)                              %if some vertices unreachable,
        Q(1:q)=find(~D);                    %...these are first-in-line
    end
    
    DP=zeros(n,1);                          %dependency
    for w=Q(1:n-1)
        BC(w)=BC(w)+DP(w);
        for v=find(P(w,:))
            DPvw=(1+DP(w)).*NP(v)./NP(w);
            DP(v)=DP(v)+DPvw;
            EBC(v,w)=EBC(v,w)+DPvw;
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%
%%% Radiality %%%
%%%%%%%%%%%%%%%%%

% code implemented by Alessandro Muscoloni
%
% Reference:
% http://www.cbmc.it/fastcent/doc/Radiality.htm

function rad = compute_radiality(dist)

dist(isinf(dist)) = 0;
dist = max(dist(:))+1 - dist;
dist(eye(size(dist))==1) = 0;
rad = sum(dist)./(size(dist,1)-1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Local Community Paradigm correlation %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% code from:
% https://sites.google.com/site/carlovittoriocannistraci/5-datasets-and-matlab-code/car-based-indices-and-local-community-paradigm
%
% please cite:
% From link prediction in brain connectomes and protein interactome
% to the local-community-paradigm in complex networks
% Cannistraci CV, Alanis-Lobato G, Ravasi T (2013) Scientific Reports 3:1613

function [LCPcorr,CN,LCL] = LCPcorr_and_LCDP(x,par)

% Evaluation of LCP-correlation (LCPcorr) and LCP-decomposition-plot(LCPDP) for a given network
% designed by Carlo Vittorio Cannistraci and revised by Gregorio Alanis Lobato, 5th april 2013

% INPUT
% x: adjacency matrix of the network
% par: indicates the use of parallel computing. It is recommended only for networks with millions of nodes or very dense network topologies.
% par accepts the following values only: 0 (serial computing) or 1 (parallel computing)

% OUTPUT
% LCPcorr: LCP-correlation
% CN: list of common neighbours for each edge in the network
% LCL: list of local-community-links for each edge in the network
% result_LCP_evaluation.mat: this matlab file containing the output variables is saved in the current folder

% EXAMPLES:
% LCPcorr_and_LCDP(x) or LCPcorr_and_LCDP(x,0): computing without parallelization
% LCPcorr_and_LCDP(x,1): computing with parallelization

if nargin==1, par=0; end

x=full(max(x,x'));
x(eye(size(x))==1)=0;
x=logical(x);

[e,r]=find(triu(x==1,1));
w=[e r]; clear e r

s=size(w,1);
jj=0; kb=0.3;
cn=zeros(s,1);
lcl=cn;
ne=cell(size(x,1),1);

if par==0
    [cn,lcl]=computa(w,x,ne,cn,lcl,jj,s,kb);
elseif par==1
    [cn,lcl]=computa_parallel(w,x,ne,cn,lcl,s);
else
    disp('%')
    disp('Error: Invalid value for "par" argument')
    disp('"par" accepts the following values only: 0 (serial computing) or 1 (parallel computing)')
    disp('%')
    return
end

clear x ne w

% figure
% plot(cn,sqrt(lcl),'.r')

CN=cn; LCL=lcl; % output
lcl = lcl(cn>0);
cn = cn(cn>0);

if isempty(cn) || sum(lcl)==0 || numel(unique(cn))==1 || numel(unique(lcl))==1
    LCPcorr=0;
else
    LCPcorr = corr(cn,lcl); % output
end

% title(['LCP-correlation = ',num2str(LCPcorr)])
% xlabel('CN'), ylabel('sqrt(LCL)')
%
% save('result_LCP_evaluation','LCPcorr','CN','LCL')

% function [jj,b]=stampa(jj,n,b)
% 
% jj=jj+1;
% jjt=jj/n;
% 
% if jjt - b > 0
%     disp(['work executed = ', num2str(100*round(jjt*10)/10),' %'])
%     b=b+0.3;
% end

function [cn,lcl]=computa(w,x,ne,cn,lcl,jj,s,kb)

for i=1:s
    
    if isempty(ne{w(i,1)})
        ne{w(i,1)}=find(x(w(i,1),:));
    end
    if isempty(ne{w(i,2)})
        ne{w(i,2)}=find(x(w(i,2),:));
    end
    
    c=intersect(ne{w(i,1)},ne{w(i,2)}); % common first neighbors
    cn(i)=numel(c);
    
    if cn(i)>1  % if there at least 2 first neighbors and one interaction
        lcl(i)=nnz(triu(x(c,c))); % number of interactions between common neighbors
    end
    
%     [jj,kb]=stampa(jj,s,kb); % indicates the percentage of work executed
    
end

function [cn,lcl]=computa_parallel(w,x,ne,cn,lcl,s)
% notice that in this parallel-function the indicator of executed work is not present

parfor i=1:size(x,1)
    ne{i}=find(x(i,:));
end

parfor i=1:s
    
    c=intersect(ne{w(i,1)},ne{w(i,2)}); % common first neighbors
    cn(i)=numel(c);
    
    if cn(i)>1  % if there at least 2 first neighbors and one interaction
        lcl(i)=nnz(triu(x(c,c))); % number of interactions between common neighbors
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%
%%% Assortativity %%%
%%%%%%%%%%%%%%%%%%%%%

% original code from:
% https://sites.google.com/site/bctnet/Home/functions/assortativity_bin.m
%
% adapted by Alessandro Muscoloni

function r = compute_assortativity(x)

%%% INPUT %%%
% x - adjacency matrix (undirected)

%%% OUTPUT %%%
% r - assortativity coefficient

% The assortativity coefficient is a correlation coefficient between the
% degrees of all nodes on two opposite ends of a link. A positive
% assortativity coefficient indicates that nodes tend to link to other
% nodes with the same or similar degree.

% Reference: Newman (2002) Phys Rev Lett 89:208701

deg = sum(x>0);
[i,j] = find(triu(x,1)>0);
K = length(i);
degi = deg(i);
degj = deg(j);

% compute assortativity
r = ( sum(degi.*degj)/K - (sum(0.5*(degi+degj))/K)^2 ) / ...
    ( sum(0.5*(degi.^2+degj.^2))/K - (sum(0.5*(degi+degj))/K)^2 );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%
%%% Modularity %%%
%%%%%%%%%%%%%%%%%%

% code from the Brain Connectivity Toolbox
% https://sites.google.com/site/bctnet/
%
% please cite:
% Complex network measures of brain connectivity: Uses and interpretations.
% Rubinov M, Sporns O (2010) NeuroImage 52:1059-69.

function [Ci,Q]=modularity_und(A)

%MODULARITY_UND     Optimal community structure and modularity
%
%   Ci = modularity_und(W);
%   [Ci Q] = modularity_und(W);
%
%   The optimal community structure is a subdivision of the network into
%   nonoverlapping groups of nodes in a way that maximizes the number of
%   within-group edges, and minimizes the number of between-group edges.
%   The modularity is a statistic that quantifies the degree to which the
%   network may be subdivided into such clearly delineated groups.
%
%   Input:      W,      undirected (weighted or binary) connection matrix.
%
%   Outputs:    Ci,     optimal community structure
%               Q,      maximized modularity
%
%   Note: Ci and Q may vary from run to run, due to heuristics in the
%   algorithm. Consequently, it may be worth to compare multiple runs.
%   Also see Good et al. (2010) Phys. Rev. E 81:046106.
%
%   Reference: Newman (2006) -- Phys Rev E 74:036104, PNAS 23:8577-8582.
%
%
%   2008-2010
%   Mika Rubinov, UNSW
%   Jonathan Power, WUSTL
%   Alexandros Goulas, Maastricht University
%   Dani Bassett, UCSB


%   Modification History:
%   Jul 2008: Original (Mika Rubinov)
%   Oct 2008: Positive eigenvalues made insufficient for division (Jonathan Power)
%   Dec 2008: Fine-tuning made consistent with Newman's description (Jonathan Power)
%   Dec 2008: Fine-tuning vectorized (Mika Rubinov)
%   Sep 2010: Node identities permuted (Dani Bassett)

N=length(A);                            %number of vertices
n_perm = randperm(N);                   %DB: randomly permute order of nodes
A = A(n_perm,n_perm);                   %DB: use permuted matrix for subsequent analysis
K=sum(A);                               %degree
m=sum(K);                               %number of edges
B=A-(K.'*K)/m;                          %modularity matrix
Ci=ones(N,1);                           %community indices
cn=1;                                   %number of communities
U=[1 0];                                %array of unexamined communites

ind=1:N;
Bg=B;
Ng=N;

while U(1)                              %examine community U(1)
    [V D]=eig(Bg);
    [d1 i1]=max(diag(D));               %most positive eigenvalue of Bg
    v1=V(:,i1);                         %corresponding eigenvector
    
    S=ones(Ng,1);
    S(v1<0)=-1;
    q=S.'*Bg*S;                         %contribution to modularity
    
    if q>1e-10                       	%contribution positive: U(1) is divisible
        qmax=q;                         %maximal contribution to modularity
        Bg(logical(eye(Ng)))=0;      	%Bg is modified, to enable fine-tuning
        indg=ones(Ng,1);                %array of unmoved indices
        Sit=S;
        while any(indg);                %iterative fine-tuning
            Qit=qmax-4*Sit.*(Bg*Sit); 	%this line is equivalent to:
            qmax=max(Qit.*indg);        %for i=1:Ng
            imax=(Qit==qmax);           %	Sit(i)=-Sit(i);
            Sit(imax)=-Sit(imax);       %	Qit(i)=Sit.'*Bg*Sit;
            indg(imax)=nan;             %	Sit(i)=-Sit(i);
            if qmax>q;                  %end
                q=qmax;
                S=Sit;
            end
        end
        
        if abs(sum(S))==Ng              %unsuccessful splitting of U(1)
            U(1)=[];
        else
            cn=cn+1;
            Ci(ind(S==1))=U(1);         %split old U(1) into new U(1) and into cn
            Ci(ind(S==-1))=cn;
            U=[cn U];
        end
    else                                %contribution nonpositive: U(1) is indivisible
        U(1)=[];
    end
    
    ind=find(Ci==U(1));                 %indices of unexamined community U(1)
    bg=B(ind,ind);
    Bg=bg-diag(sum(bg));                %modularity matrix for U(1)
    Ng=length(ind);                     %number of vertices in U(1)
end

s=Ci(:,ones(1,N));                      %compute modularity
Q=~(s-s.').*B/m;
Q=sum(Q(:));
Ci_corrected = zeros(N,1);              % DB: initialize Ci_corrected
Ci_corrected(n_perm) = Ci;              % DB: return order of nodes to the order used at the input stage.
Ci = Ci_corrected;                      % DB: output corrected community assignments

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Structural consistency %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% original code provided by the authors
% and adapted by Carlo Vittorio Cannistraci
%
% Reference:
% Toward link predictability of complex networks,
% Proceedings of the National Academy of Sciences, 201424644 (2015).
% by Linyuan Lu, Liming Pan, Tao Zhou, Yi-Cheng Zhang and H. Eugene Stanley.
% http://www.pnas.org/content/early/2015/02/05/1424644112.
% Coded by Liming Pan.

function fine=avg_structCons_carlo(Adj, iterations, perc) %(fnameTraining,fname)

if ~isempty(Adj)
    % structuralConsistency(fnameTraining,fname) returns the structural
    % consistency of the training network compared to the full network.
    % Inputs:  fnameTraining, the file name of the Training network
    %          fname, the file name of the full network
    % Output:  consistVal, the value of the structural consistency index.
    % the network adjacency list is stored in the following format for default:
    % The node number starts at 1. Undirected links are stored twice.
    % For example, network of two nodes connected by a single link is stored as
    % 1 2 1
    % 2 1 1
    
    %Load the training network and the full network
    %AdjTraining=spconvert(load(fnameTraining));
    %Adj=spconvert(load(fname));
    
    %default values for the parameters
    if nargin==1
        iterations=10; % number of iterations to estimate an average struct. consist.
        % use 10 iteration for speed and 100 for precision
        perc=0.1; % percentage of links removed from Adj to create AdjTraining
    elseif nargin==2
        perc=0.1; % percentage of links removed from Adj to create AdjTraining
    end
    
    fine=zeros(1,iterations);
    for i=1:iterations
        
        AdjTraining=adtrai(Adj, perc);
        
        %Size of the probe set
        probeSize=(nnz(Adj)-nnz(AdjTraining))/2;
        
        probMatrix=perturbation(AdjTraining,Adj);
        index=find(tril(~AdjTraining,-1));
        [row,col]=ind2sub(size(tril(AdjTraining,-1)),index);
        weight=probMatrix(index);
        [~,y]=sort(weight);
        consistVal=0;
        for j=(length(y)-probeSize+1):length(y)
            if Adj(row(y(j)),col(y(j)))==1
                consistVal=consistVal+1;
            end
        end
        fine(i)=consistVal/(probeSize);
        %return;
        
    end
    
    fine=mean(fine);
else
    fine = NaN;
end

function tmp=adtrai(x, perc)

nn = size(x,1);
[r,c]=find(triu(x,1));
w=[r c];clear r c
d=size(w,1);

tmp = triu(x, 1);
num=round(d * perc);

if num <= d
    idx = randsample(d, num);
else
    idx = randsample(d, d);
end
%num = numel(idx);

%tmp(sub2ind(size(tmp), w(idx, 1), w(idx, 2))) = 0;
tmp(sub2ind([nn, nn], w(idx, 1), w(idx, 2))) = 0;
tmp = max(tmp, tmp');
%all_matrices{i, j} = tmp;
%wf=[[wm; w(idx,:)] [zeros(sm,1); ones(num,1)]];

function AdjAnneal=perturbation(AdjTraining,Adj)
% perturbation(AdjTraining,Adj) returns the perturbated matrix of the original
% adjaceny matrix.
% Inputs:  AdjTraining, the unperturbated network,
%          Adj, The unperturbated network plus the perturbations.
% Outputs: AdjAnneal, the perturbated matrix of AdjTraining.

% eigen decomposition of AdjTraining
N=length(Adj);
AdjTraining=full(AdjTraining);
[v,w]=eig(AdjTraining);
eigenValues=diag(w);

% find "correct" eigenvectors for perturbation of degenerate eigenvalues
degenSign=zeros(N,1);

%v2 and w2 are the "correct" eigenvectors and eigenvalues
v2=v;
w2=eigenValues;
AdjPertu=Adj-AdjTraining;
for l=1:N
    if degenSign(l)==0
        tempEigen=find(abs((eigenValues-eigenValues(l)))<10e-12);
        if length(tempEigen)>1
            vRedun=v(1:end,tempEigen);
            m=vRedun'*AdjPertu*vRedun;
            m=(m+m')./2;
            m=full(m);
            [v_r,w_r]=eig(m);
            vRedun=vRedun*v_r;
            % renormalized the  new eigenvectors
            for o=1:length(m)
                vRedun(1:end,o)=vRedun(1:end,o)./norm(vRedun(1:end,o));
            end
            v2(1:end,tempEigen)=vRedun;
            w2(tempEigen)=eigenValues(tempEigen)+diag(w_r);
            degenSign(tempEigen)=1;
        end
    end
end

% pertubate the adjacency matrix AdjTraining
AdjAnneal=v2*diag(diag(v2'*Adj*v2))*v2';
%return;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Power-lawness gamma %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% code from:
% http://www.santafe.edu/~aaronc/powerlaws/
%
% please cite:
% A. Clauset, C.R. Shalizi, and M.E.J. Newman,
% "Power-law distributions in empirical data",
% SIAM Review 51(4), 661-703 (2009) (arXiv:0706.1062, doi:10.1137/070710111)

function [alpha, xmin, L]=plfit(x, varargin)
% PLFIT fits a power-law distributional model to data.
%    Source: http://www.santafe.edu/~aaronc/powerlaws/
%
%    PLFIT(x) estimates x_min and alpha according to the goodness-of-fit
%    based method described in Clauset, Shalizi, Newman (2007). x is a
%    vector of observations of some quantity to which we wish to fit the
%    power-law distribution p(x) ~ x^-alpha for x >= xmin.
%    PLFIT automatically detects whether x is composed of real or integer
%    values, and applies the appropriate method. For discrete data, if
%    min(x) > 1000, PLFIT uses the continuous approximation, which is
%    a reliable in this regime.
%
%    The fitting procedure works as follows:
%    1) For each possible choice of x_min, we estimate alpha via the
%       method of maximum likelihood, and calculate the Kolmogorov-Smirnov
%       goodness-of-fit statistic D.
%    2) We then select as our estimate of x_min, the value that gives the
%       minimum value D over all values of x_min.
%
%    Note that this procedure gives no estimate of the uncertainty of the
%    fitted parameters, nor of the validity of the fit.
%
%    Example:
%       x = (1-rand(10000,1)).^(-1/(2.5-1));
%       [alpha, xmin, L] = plfit(x);
%
%    The output 'alpha' is the maximum likelihood estimate of the scaling
%    exponent, 'xmin' is the estimate of the lower bound of the power-law
%    behavior, and L is the log-likelihood of the data x>=xmin under the
%    fitted power law.
%
%    For more information, try 'type plfit'
%
%    See also PLVAR, PLPVA

% Version 1.0    (2007 May)
% Version 1.0.2  (2007 September)
% Version 1.0.3  (2007 September)
% Version 1.0.4  (2008 January)
% Version 1.0.5  (2008 March)
% Version 1.0.6  (2008 July)
% Version 1.0.7  (2008 October)
% Version 1.0.8  (2009 February)
% Version 1.0.9  (2009 October)
% Version 1.0.10 (2010 January)
% Version 1.0.11 (2012 January)
% Copyright (C) 2008-2012 Aaron Clauset (Santa Fe Institute)
% Distributed under GPL 2.0
% http://www.gnu.org/copyleft/gpl.html
% PLFIT comes with ABSOLUTELY NO WARRANTY
%
% Notes:
%
% 1. In order to implement the integer-based methods in Matlab, the numeric
%    maximization of the log-likelihood function was used. This requires
%    that we specify the range of scaling parameters considered. We set
%    this range to be [1.50 : 0.01 : 3.50] by default. This vector can be
%    set by the user like so,
%
%       a = plfit(x,'range',[1.001:0.001:5.001]);
%
% 2. PLFIT can be told to limit the range of values considered as estimates
%    for xmin in three ways. First, it can be instructed to sample these
%    possible values like so,
%
%       a = plfit(x,'sample',100);
%
%    which uses 100 uniformly distributed values on the sorted list of
%    unique values in the data set. Second, it can simply omit all
%    candidates above a hard limit, like so
%
%       a = plfit(x,'limit',3.4);
%
%    Finally, it can be forced to use a fixed value, like so
%
%       a = plfit(x,'xmin',3.4);
%
%    In the case of discrete data, it rounds the limit to the nearest
%    integer.
%
% 3. When the input sample size is small (e.g., < 100), the continuous
%    estimator is slightly biased (toward larger values of alpha). To
%    explicitly use an experimental finite-size correction, call PLFIT like
%    so
%
%       a = plfit(x,'finite');
%
%    which does a small-size correction to alpha.
%
% 4. For continuous data, PLFIT can return erroneously large estimates of
%    alpha when xmin is so large that the number of obs x >= xmin is very
%    small. To prevent this, we can truncate the search over xmin values
%    before the finite-size bias becomes significant by calling PLFIT as
%
%       a = plfit(x,'nosmall');
%
%    which skips values xmin with finite size bias > 0.1.

vec     = [];
sample  = [];
xminx   = [];
limit   = [];
finite  = false;
nosmall = false;
nowarn  = false;

% parse command-line parameters; trap for bad input
i=1;
while i<=length(varargin),
    argok = 1;
    if ischar(varargin{i}),
        switch varargin{i},
            case 'range',        vec     = varargin{i+1}; i = i + 1;
            case 'sample',       sample  = varargin{i+1}; i = i + 1;
            case 'limit',        limit   = varargin{i+1}; i = i + 1;
            case 'xmin',         xminx   = varargin{i+1}; i = i + 1;
            case 'finite',       finite  = true;
            case 'nowarn',       nowarn  = true;
            case 'nosmall',      nosmall = true;
            otherwise, argok=0;
        end
    end
    if ~argok,
        disp(['(PLFIT) Ignoring invalid argument #' num2str(i+1)]);
    end
    i = i+1;
end
if ~isempty(vec) && (~isvector(vec) || min(vec)<=1),
    fprintf('(PLFIT) Error: ''range'' argument must contain a vector; using default.\n');
    vec = [];
end;
if ~isempty(sample) && (~isscalar(sample) || sample<2),
    fprintf('(PLFIT) Error: ''sample'' argument must be a positive integer > 1; using default.\n');
    sample = [];
end;
if ~isempty(limit) && (~isscalar(limit) || limit<min(x)),
    fprintf('(PLFIT) Error: ''limit'' argument must be a positive value >= 1; using default.\n');
    limit = [];
end;
if ~isempty(xminx) && (~isscalar(xminx) || xminx>=max(x)),
    fprintf('(PLFIT) Error: ''xmin'' argument must be a positive value < max(x); using default behavior.\n');
    xminx = [];
end;

% reshape input vector
x = reshape(x,numel(x),1);

% select method (discrete or continuous) for fitting
if     isempty(setdiff(x,floor(x))), f_dattype = 'INTS';
elseif isreal(x),    f_dattype = 'REAL';
else                 f_dattype = 'UNKN';
end;
if strcmp(f_dattype,'INTS') && min(x) > 1000 && length(x)>100,
    f_dattype = 'REAL';
end;

% estimate xmin and alpha, accordingly
switch f_dattype,
    
    case 'REAL',
        xmins = unique(x);
        xmins = xmins(1:end-1);
        if ~isempty(xminx),
            xmins = xmins(find(xmins>=xminx,1,'first'));
        end;
        if ~isempty(limit),
            xmins(xmins>limit) = [];
        end;
        if ~isempty(sample),
            xmins = xmins(unique(round(linspace(1,length(xmins),sample))));
        end;
        dat   = zeros(size(xmins));
        z     = sort(x);
        for xm=1:length(xmins)
            xmin = xmins(xm);
            z    = z(z>=xmin);
            n    = length(z);
            % estimate alpha using direct MLE
            a    = n ./ sum( log(z./xmin) );
            if nosmall,
                if (a-1)/sqrt(n) > 0.1
                    dat(xm:end) = [];
                    xm = length(xmins)+1;
                    break;
                end;
            end;
            % compute KS statistic
            cx   = (0:n-1)'./n;
            cf   = 1-(xmin./z).^a;
            dat(xm) = max( abs(cf-cx) );
        end;
        D     = min(dat);
        xmin  = xmins(find(dat<=D,1,'first'));
        z     = x(x>=xmin);
        n     = length(z);
        alpha = 1 + n ./ sum( log(z./xmin) );
        if finite, alpha = alpha*(n-1)/n+1/n; end; % finite-size correction
        if n < 50 && ~finite && ~nowarn,
            fprintf('(PLFIT) Warning: finite-size bias may be present.\n');
        end;
        L = n*log((alpha-1)/xmin) - alpha.*sum(log(z./xmin));
        
    case 'INTS',
        
        if isempty(vec),
            vec  = (1.50:0.01:3.50);    % covers range of most practical
        end;                            % scaling parameters
        zvec = zeta(vec);
        
        xmins = unique(x);
        xmins = xmins(1:end-1);
        if ~isempty(xminx),
            xmins = xmins(find(xmins>=xminx,1,'first'));
        end;
        if ~isempty(limit),
            limit = round(limit);
            xmins(xmins>limit) = [];
        end;
        if ~isempty(sample),
            xmins = xmins(unique(round(linspace(1,length(xmins),sample))));
        end;
        if isempty(xmins)
            fprintf('(PLFIT) Error: x must contain at least two unique values.\n');
            alpha = NaN; xmin = x(1); D = NaN;
            return;
        end;
        xmax   = max(x);
        dat    = zeros(length(xmins),2);
        z      = x;
        fcatch = 0;
        
        for xm=1:length(xmins)
            xmin = xmins(xm);
            z    = z(z>=xmin);
            n    = length(z);
            % estimate alpha via direct maximization of likelihood function
            if fcatch==0
                try
                    % vectorized version of numerical calculation
                    zdiff = sum( repmat((1:xmin-1)',1,length(vec)).^-repmat(vec,xmin-1,1) ,1);
                    L = -vec.*sum(log(z)) - n.*log(zvec - zdiff);
                catch
                    % catch: force loop to default to iterative version for
                    % remainder of the search
                    fcatch = 1;
                end;
            end;
            if fcatch==1
                % force iterative calculation (more memory efficient, but
                % can be slower)
                L       = -Inf*ones(size(vec));
                slogz   = sum(log(z));
                xminvec = (1:xmin-1);
                for k=1:length(vec)
                    L(k) = -vec(k)*slogz - n*log(zvec(k) - sum(xminvec.^-vec(k)));
                end
            end;
            [Y,I] = max(L);
            % compute KS statistic
            fit = cumsum((((xmin:xmax).^-vec(I)))./ (zvec(I) - sum((1:xmin-1).^-vec(I))));
            cdi = cumsum(hist(z,xmin:xmax)./n);
            dat(xm,:) = [max(abs( fit - cdi )) vec(I)];
        end
        % select the index for the minimum value of D
        [D,I] = min(dat(:,1));
        xmin  = xmins(I);
        z     = x(x>=xmin);
        n     = length(z);
        alpha = dat(I,2);
        if finite, alpha = alpha*(n-1)/n+1/n; end; % finite-size correction
        if n < 50 && ~finite && ~nowarn,
            fprintf('(PLFIT) Warning: finite-size bias may be present.\n');
        end;
        L     = -alpha*sum(log(z)) - n*log(zvec(find(vec<=alpha,1,'last')) - sum((1:xmin-1).^-alpha));
        
    otherwise,
        fprintf('(PLFIT) Error: x must contain only reals or only integers.\n');
        alpha = [];
        xmin  = [];
        L     = [];
        return;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Power-lawness p-value %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% code from:
% http://www.santafe.edu/~aaronc/powerlaws/
%
% please cite:
% A. Clauset, C.R. Shalizi, and M.E.J. Newman,
% "Power-law distributions in empirical data",
% SIAM Review 51(4), 661-703 (2009) (arXiv:0706.1062, doi:10.1137/070710111)

function [p,gof,err]=plpva(x, xmin, varargin)

% PLPVA calculates the p-value for the given power-law fit to some data.
%    Source: http://www.santafe.edu/~aaronc/powerlaws/
%
%    PLPVA(x, xmin) takes data x and given lower cutoff for the power-law
%    behavior xmin and computes the corresponding p-value for the
%    Kolmogorov-Smirnov test, according to the method described in
%    Clauset, Shalizi, Newman (2007).
%    PLPVA automatically detects whether x is composed of real or integer
%    values, and applies the appropriate method. For discrete data, if
%    min(x) > 1000, PLPVA uses the continuous approximation, which is
%    a reliable in this regime.
%
%    The fitting procedure works as follows:
%    1) For each possible choice of x_min, we estimate alpha via the
%       method of maximum likelihood, and calculate the Kolmogorov-Smirnov
%       goodness-of-fit statistic D.
%    2) We then select as our estimate of x_min, the value that gives the
%       minimum value D over all values of x_min.
%
%    Note that this procedure gives no estimate of the uncertainty of the
%    fitted parameters, nor of the validity of the fit.
%
%    Example:
%       x = (1-rand(10000,1)).^(-1/(2.5-1));
%       [p, gof] = plpva(x, 1);
%
%    For more information, try 'type plpva'
%
%    See also PLFIT, PLVAR

% Version 1.0   (2007 May)
% Version 1.0.2 (2007 September)
% Version 1.0.3 (2007 September)
% Version 1.0.4 (2008 January)
% Version 1.0.5 (2008 March)
% Version 1.0.6 (2008 April)
% Version 1.0.7 (2009 October)
% Version 1.0.8 (2012 January)
% Copyright (C) 2008-2012 Aaron Clauset (Santa Fe Institute)
% Distributed under GPL 2.0
% http://www.gnu.org/copyleft/gpl.html
% PLPVA comes with ABSOLUTELY NO WARRANTY
%
% Notes:
%
% 1. In order to implement the integer-based methods in Matlab, the numeric
%    maximization of the log-likelihood function was used. This requires
%    that we specify the range of scaling parameters considered. We set
%    this range to be [1.50 : 0.01 : 3.50] by default. This vector can be
%    set by the user like so,
%
%       p = plpva(x, 1,'range',[1.001:0.001:5.001]);
%
% 2. PLPVA can be told to limit the range of values considered as estimates
%    for xmin in two ways. First, it can be instructed to sample these
%    possible values like so,
%
%       a = plpva(x,1,'sample',100);
%
%    which uses 100 uniformly distributed values on the sorted list of
%    unique values in the data set. Second, it can simply omit all
%    candidates above a hard limit, like so
%
%       a = plpva(x,1,'limit',3.4);
%
%    Finally, it can be forced to use a fixed value, like so
%
%       a = plpva(x,1,'xmin',1);
%
%    In the case of discrete data, it rounds the limit to the nearest
%    integer.
%
% 3. The default number of semiparametric repetitions of the fitting
% procedure is 1000. This number can be changed like so
%
%       p = plvar(x, 1,'reps',10000);
%
% 4. To silence the textual output to the screen, do this
%
%       p = plpva(x, 1,'reps',10000,'silent');
%

err = zeros(1,1);
vec    = [];
sample = [];
limit  = [];
xminx  = [];
Bt     = [];
quiet  = false;
persistent rand_state;

% parse command-line parameters; trap for bad input
i=1;
while i<=length(varargin),
    argok = 1;
    if ischar(varargin{i}),
        switch varargin{i},
            case 'range',        vec    = varargin{i+1}; i = i + 1;
            case 'sample',       sample = varargin{i+1}; i = i + 1;
            case 'limit',        limit  = varargin{i+1}; i = i + 1;
            case 'xmin',         xminx  = varargin{i+1}; i = i + 1;
            case 'reps',         Bt     = varargin{i+1}; i = i + 1;
            case 'silent',       quiet  = true;
            otherwise, argok=0;
        end
    end
    if ~argok,
        disp(['(PLPVA) Ignoring invalid argument #' num2str(i+1)]);
    end
    i = i+1;
end
if ~isempty(vec) && (~isvector(vec) || min(vec)<=1),
    fprintf('(PLPVA) Error: ''range'' argument must contain a vector; using default.\n');
    vec = [];
end;
if ~isempty(sample) && (~isscalar(sample) || sample<2),
    fprintf('(PLPVA) Error: ''sample'' argument must be a positive integer > 1; using default.\n');
    sample = [];
end;
if ~isempty(limit) && (~isscalar(limit) || limit<1),
    fprintf('(PLPVA) Error: ''limit'' argument must be a positive value >= 1; using default.\n');
    limit = [];
end;
if ~isempty(Bt) && (~isscalar(Bt) || Bt<2),
    fprintf('(PLPVA) Error: ''reps'' argument must be a positive value > 1; using default.\n');
    Bt = [];
end;
if ~isempty(xminx) && (~isscalar(xminx) || xminx>=max(x)),
    fprintf('(PLPVA) Error: ''xmin'' argument must be a positive value < max(x); using default behavior.\n');
    xminx = [];
end;
try
    
    % reshape input vector
    x = reshape(x,numel(x),1);
    
    % select method (discrete or continuous) for fitting
    if     isempty(setdiff(x,floor(x))), f_dattype = 'INTS';
    elseif isreal(x),    f_dattype = 'REAL';
    else                 f_dattype = 'UNKN';
    end;
    if strcmp(f_dattype,'INTS') && min(x) > 1000 && length(x)>100,
        f_dattype = 'REAL';
    end;
    N = length(x);
    x = reshape(x,N,1); % guarantee x is a column vector
    if isempty(rand_state)
        rand_state = cputime;
        rand('twister',sum(100*clock));
    end;
    if isempty(Bt), Bt = 1000; end;
    nof = zeros(Bt,1);
    
    if ~quiet,
        fprintf('Power-law Distribution, p-value calculation\n');
        fprintf('   Copyright 2007-2010 Aaron Clauset\n');
        fprintf('   Warning: This can be a slow calculation; please be patient.\n');
        fprintf('   n    = %i\n   xmin = %6.4f\n   reps = %i\n',length(x),xmin,length(nof));
    end;
    tic;
    
    
    
    % estimate xmin and alpha, accordingly
    switch f_dattype,
        
        case 'REAL',
            
            % compute D for the empirical distribution
            z     = x(x>=xmin);	nz   = length(z);
            y     = x(x<xmin); 	ny   = length(y);
            alpha = 1 + nz ./ sum( log(z./xmin) );
            cz    = (0:nz-1)'./nz;
            cf    = 1-(xmin./sort(z)).^(alpha-1);
            gof   = max( abs(cz - cf) );
            pz    = nz/N;
            
            % compute distribution of gofs from semi-parametric bootstrap
            % of entire data set with fit
            for B=1:length(nof)
                % semi-parametric bootstrap of data
                n1 = sum(rand(N,1)>pz);
                q1 = y(ceil(ny.*rand(n1,1)));
                n2 = N-n1;
                q2 = xmin*(1-rand(n2,1)).^(-1/(alpha-1));
                q  = sort([q1; q2]);
                
                % estimate xmin and alpha via GoF-method
                qmins = unique(q);
                qmins = qmins(1:end-1);
                if ~isempty(xminx),
                    qmins = qmins(find(qmins>=xminx,1,'first'));
                end;
                if ~isempty(limit),
                    qmins(qmins>limit) = [];
                    if isempty(qmins), qmins = min(q); end;
                end;
                if ~isempty(sample),
                    qmins = qmins(unique(round(linspace(1,length(qmins),sample))));
                end;
                dat   = zeros(size(qmins));
                for qm=1:length(qmins)
                    qmin = qmins(qm);
                    zq   = q(q>=qmin);
                    nq   = length(zq);
                    a    = nq ./ sum( log(zq./qmin) );
                    cq   = (0:nq-1)'./nq;
                    cf   = 1-(qmin./zq).^a;
                    dat(qm) = max( abs(cq - cf) );
                end;
                if ~quiet,
                    fprintf('[%i]\tp = %6.4f\t[%4.2fm]\n',B,sum(nof(1:B)>=gof)./B,toc/60);
                end;
                % store distribution of estimated gof values
                nof(B) = min(dat);
            end;
            p = sum(nof>=gof)./length(nof);
            
        case 'INTS',
            
            if isempty(vec),
                vec  = (1.50:0.01:3.50);    % covers range of most practical
            end;                            % scaling parameters
            zvec = zeta(vec);
            
            % compute D for the empirical distribution
            z     = x(x>=xmin);	nz   = length(z);	xmax = max(z);
            y     = x(x<xmin); 	ny   = length(y);
            
            L  = -Inf*ones(size(vec));
            for k=1:length(vec)
                L(k) = -vec(k)*sum(log(z)) - nz*log(zvec(k) - sum((1:xmin-1).^-vec(k)));
            end
            [Y,I] = max(L);
            alpha = vec(I);
            
            fit = cumsum((((xmin:xmax).^-alpha))./ (zvec(I) - sum((1:xmin-1).^-alpha)));
            cdi = cumsum(hist(z,(xmin:xmax))./nz);
            gof = max(abs( fit - cdi ));
            pz  = nz/N;
            
            mmax = 20*xmax;
            %         if length((1:mmax+1)' )~=length([cumsum(pdf); 1])
            %             err=1; p=-1; gof=-1;
            %         else
            %
            %
            
            
            
            pdf = [zeros(xmin-1,1); (((xmin:mmax).^-alpha))'./ (zvec(I) - sum((1:xmin-1).^-alpha))];
            cdf = [(1:mmax+1)' [cumsum(pdf); 1]];
            
            
            
            
            
            % compute distribution of gofs from semi-parametric bootstrap
            % of entire data set with fit
            for B=1:length(nof)
                % semi-parametric bootstrap of data
                n1 = sum(rand(N,1)>pz);
                q1 = y(ceil(ny.*rand(n1,1)));
                n2 = N-n1;
                
                % simple discrete zeta generator
                r2 = sort(rand(n2,1));  c = 1;
                q2 = zeros(n2,1);	    k = 1;
                for i=xmin:mmax+1
                    while c<=length(r2) && r2(c)<=cdf(i,2), c=c+1; end;
                    q2(k:c-1) = i;
                    k = c;
                    if k>n2, break; end;
                end;
                q = [q1; q2];
                
                % estimate xmin and alpha via GoF-method
                qmins = unique(q);
                qmins = qmins(1:end-1);
                if ~isempty(xminx),
                    qmins = qmins(find(qmins>=xminx,1,'first'));
                end;
                if ~isempty(limit),
                    qmins(qmins>limit) = [];
                    if isempty(qmins), qmins = min(q); end;
                end;
                if ~isempty(sample),
                    qmins = qmins(unique(round(linspace(1,length(qmins),sample))));
                end;
                dat   = zeros(size(qmins));
                qmax  = max(q); zq = q;
                for qm=1:length(qmins)
                    qmin = qmins(qm);
                    zq   = zq(zq>=qmin);
                    nq   = length(zq);
                    if nq>1
                        try
                            % vectorized version of numerical calculation
                            zdiff = sum( repmat((1:qmin-1)',1,length(vec)).^-repmat(vec,qmin-1,1) ,1);
                            L = -vec.*sum(log(zq)) - nq.*log(zvec - zdiff);
                        catch
                            % iterative version (more memory efficient, but slower)
                            L       = -Inf*ones(size(vec));
                            slogzq  = sum(log(zq));
                            qminvec = (1:qmin-1);
                            for k=1:length(vec)
                                L(k) = -vec(k)*slogzq - nq*log(zvec(k) - sum(qminvec.^-vec(k)));
                            end;
                            
                        end;
                        [Y,I] = max(L);
                        
                        fit = cumsum((((qmin:qmax).^-vec(I)))./ (zvec(I) - sum((1:qmin-1).^-vec(I))));
                        cdi = cumsum(hist(zq,(qmin:qmax))./nq);
                        dat(qm) = max(abs( fit - cdi ));
                    else
                        dat(qm) = -Inf;
                    end;
                    
                end
                if ~quiet,
                    fprintf('[%i]\tp = %6.4f\t[%4.2fm]\n',B,sum(nof(1:B)>=gof)./B,toc/60);
                end;
                % -- store distribution of estimated gof values
                nof(B) = min(dat);
            end;
            p = sum(nof>=gof)./length(nof);
            
        otherwise,
            fprintf('(PLPVA) Error: x must contain only reals or only integers.\n');
            p   = [];
            gof = [];
            return;
    end;
    
catch
    p=NaN;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%
%%% Small-worldness %%%
%%%%%%%%%%%%%%%%%%%%%%%

% code for the null models from the Brain Connectivity Toolbox
% https://sites.google.com/site/bctnet/
%
% please cite:
% Complex network measures of brain connectivity: Uses and interpretations.
% Rubinov M, Sporns O (2010) NeuroImage 52:1059-69.

% code for computing the smallworld measures implemented by Alessandro Muscoloni
%
% Reference:
% "The Ubiquity of Small-World Networks"
% Telesford et al. (2011), Brain Connect

% omega (range from -1 to 1)
% considered small-world for omega~=0

% sigma (range from 0 to infinity)
% considered small-world for sigma>1

function omega = compute_smallworld_omega(x, x_rand, x_latt)

dist = graphallshortestpaths(x, 'Directed', false);
L = mean(dist(~isinf(dist) & dist>0));
C = mean(clustering_coef_bu(x));

L_r = zeros(size(x_rand));
for i = 1:length(L_r)
    dist = graphallshortestpaths(x_rand{i}, 'Directed', false);
    L_r(i) = mean(dist(~isinf(dist) & dist>0));
end
L_r = mean(L_r);

C_l = zeros(size(x_latt));
for i = 1:length(C_l)
    C_l(i) = mean(clustering_coef_bu(x_latt{i}));
end
C_l = mean(C_l);

omega = (L_r/L) - (C/C_l);

function sigma = compute_smallworld_sigma(x, x_rand)

dist = graphallshortestpaths(x, 'Directed', false);
L = mean(dist(~isinf(dist) & dist>0));
C = mean(clustering_coef_bu(x));

L_r = zeros(size(x_rand));
C_r = zeros(size(x_rand));
for i = 1:length(L_r)
    dist = graphallshortestpaths(x_rand{i}, 'Directed', false);
    L_r(i) = mean(dist(~isinf(dist) & dist>0));
    C_r(i) = mean(clustering_coef_bu(x_rand{i}));
end
C_r = mean(C_r);
L_r = mean(L_r);

sigma = (C/C_r) / (L/L_r);

function omega_eff = compute_smallworld_omega_eff(x, x_rand, x_latt)

[eff_glob, eff_loc] = compute_efficiency(x);

eff_glob_r = zeros(size(x_rand));
for i = 1:length(eff_glob_r)
    [eff_glob_r(i), ~] = compute_efficiency(x_rand{i});
end
eff_glob_r = mean(eff_glob_r);

eff_loc_l = zeros(size(x_latt));
for i = 1:length(eff_loc_l)
    [~, eff_loc_l(i)] = compute_efficiency(x_latt{i});
end
eff_loc_l = mean(eff_loc_l);

omega_eff = (eff_glob_r/eff_glob) - (eff_loc/eff_loc_l);

function sigma_eff = compute_smallworld_sigma_eff(x, x_rand)

[eff_glob, eff_loc] = compute_efficiency(x);

eff_glob_r = zeros(size(x_rand));
eff_loc_r = zeros(size(x_rand));
for i = 1:length(eff_glob_r)
    [eff_glob_r(i), eff_loc_r(i)] = compute_efficiency(x_rand{i});
end
eff_glob_r = mean(eff_glob_r);
eff_loc_r = mean(eff_loc_r);

sigma_eff = (eff_loc/eff_loc_r) / (eff_glob/eff_glob_r);

function [R , eff] = randmio_und(R, ITER)

%RANDMIO_UND     Random graph with preserved degree distribution
%
%   R = randmio_und(W,ITER);
%   [R eff]=randmio_und(W, ITER);
%
%   This function randomizes an undirected network, while preserving the
%   degree distribution. The function does not preserve the strength
%   distribution in weighted networks.
%
%   Input:      W,      undirected (binary/weighted) connection matrix
%               ITER,   rewiring parameter
%                       (each edge is rewired approximately ITER times)
%
%   Output:     R,      randomized network
%               eff,    number of actual rewirings carried out
%
%   References: Maslov and Sneppen (2002) Science 296:910
%
%
%   2007-2012
%   Mika Rubinov, UNSW
%   Jonathan Power, WUSTL
%   Olaf Sporns, IU

%   Modification History:
%   Jun 2007: Original (Mika Rubinov)
%   Apr 2008: Edge c-d is flipped with 50% probability, allowing to explore
%             all potential rewirings (Jonathan Power)
%   Mar 2012: Limit number of rewiring attempts, count number of successful
%             rewirings (Olaf Sporns)

n=size(R,1);
[i j]=find(tril(R));
K=length(i);
ITER=K*ITER;

% maximal number of rewiring attempts per 'iter'
maxAttempts= round(n*K/(n*(n-1)));
% actual number of successful rewirings
eff = 0;

for iter=1:ITER
    att=0;
    while (att<=maxAttempts)    %while not rewired
        while 1
            e1=ceil(K*rand);
            e2=ceil(K*rand);
            while (e2==e1),
                e2=ceil(K*rand);
            end
            a=i(e1); b=j(e1);
            c=i(e2); d=j(e2);
            
            if all(a~=[c d]) && all(b~=[c d]);
                break           %all four vertices must be different
            end
        end
        
        if rand>0.5
            i(e2)=d; j(e2)=c; 	%flip edge c-d with 50% probability
            c=i(e2); d=j(e2); 	%to explore all potential rewirings
        end
        
        %rewiring condition
        if ~(R(a,d) || R(c,b))
            R(a,d)=R(a,b); R(a,b)=0;
            R(d,a)=R(b,a); R(b,a)=0;
            R(c,b)=R(c,d); R(c,d)=0;
            R(b,c)=R(d,c); R(d,c)=0;
            
            j(e1) = d;          %reassign edge indices
            j(e2) = b;
            eff = eff+1;
            break;
        end %rewiring condition
        att=att+1;
    end %while not rewired
end %iterations

function [Rlatt,Rrp,ind_rp,eff] = latmio_und(R,ITER,D)

%LATMIO_UND     Lattice with preserved degree distribution
%
%   [Rlatt,Rrp,ind_rp,eff] = latmio_und(R,ITER,D);
%
%   This function "latticizes" an undirected network, while preserving the
%   degree distribution. The function does not preserve the strength
%   distribution in weighted networks.
%
%   Input:      R,      undirected (binary/weighted) connection matrix
%               ITER,   rewiring parameter
%                       (each edge is rewired approximately ITER times)
%               D,      distance-to-diagonal matrix
%
%   Output:     Rlatt,  latticized network in original node ordering
%               Rrp,    latticized network in node ordering used for
%                       latticization
%               ind_rp, node ordering used for latticization
%               eff,    number of actual rewirings carried out
%
%   References: Maslov and Sneppen (2002) Science 296:910
%               Sporns and Zwi (2004) Neuroinformatics 2:145
%
%   2007-2012
%   Mika Rubinov, UNSW
%   Jonathan Power, WUSTL
%   Olaf Sporns, IU

%   Modification History:
%   Jun 2007: Original (Mika Rubinov)
%   Apr 2008: Edge c-d is flipped with 50% probability, allowing to explore
%             all potential rewirings (Jonathan Power)
%   Feb 2012: limit on number of attempts, distance-to-diagonal as input,
%             count number of successful rewirings (Olaf Sporns)
%   Feb 2012: permute node ordering on each run, to ensure lattices are
%             shuffled across mutliple runs (Olaf Sporns)

n=size(R,1);

% randomly reorder matrix
ind_rp = randperm(n);
R = R(ind_rp,ind_rp);

% create 'distance to diagonal' matrix
if nargin<3 %if D is not specified by user
    D=zeros(n);
    u=[0 min([mod(1:n-1,n);mod(n-1:-1:1,n)])];
    for v=1:ceil(n/2)
        D(n-v+1,:)=u([v+1:n 1:v]);
        D(v,:)=D(n-v+1,n:-1:1);
    end
end
%end create

[i j]=find(tril(R));
K=length(i);
ITER=K*ITER;

% maximal number of rewiring attempts per 'iter'
maxAttempts= round(n*K/(n*(n-1)/2));
% actual number of successful rewirings
eff = 0;

for iter=1:ITER
    att=0;
    while (att<=maxAttempts)    %while not rewired
        while 1
            e1=ceil(K*rand);
            e2=ceil(K*rand);
            while (e2==e1),
                e2=ceil(K*rand);
            end
            a=i(e1); b=j(e1);
            c=i(e2); d=j(e2);
            
            if all(a~=[c d]) && all(b~=[c d]);
                break           %all four vertices must be different
            end
        end
        
        if rand>0.5
            i(e2)=d; j(e2)=c; 	%flip edge c-d with 50% probability
            c=i(e2); d=j(e2); 	%to explore all potential rewirings
        end
        
        %rewiring condition
        if ~(R(a,d) || R(c,b))
            %lattice condition
            if (D(a,b)*R(a,b)+D(c,d)*R(c,d))>=(D(a,d)*R(a,b)+D(c,b)*R(c,d))
                R(a,d)=R(a,b); R(a,b)=0;
                R(d,a)=R(b,a); R(b,a)=0;
                R(c,b)=R(c,d); R(c,d)=0;
                R(b,c)=R(d,c); R(d,c)=0;
                
                j(e1) = d;          %reassign edge indices
                j(e2) = b;
                eff = eff+1;
                break;
            end %lattice condition
        end %rewiring condition
        att=att+1;
    end %while not rewired
end %iterations

% lattice in node order used for latticization
Rrp = R;
% reverse random permutation of nodes
[~,ind_rp_reverse] = sort(ind_rp);
Rlatt = Rrp(ind_rp_reverse,ind_rp_reverse);