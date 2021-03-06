function output_hu_style(dname)
%% start up
dataname = dname;
%% start up parameters
K=50;    % kmeans's cluster NO.
run_demo=0;
%% add path
Data_Path='data';
Data_Path=fullfile(Data_Path,dataname);
lines_Path=fullfile(Data_Path,'3dlines');
patch_Path=fullfile(Data_Path,'patch');
kernel_Path=fullfile(Data_Path,'kernel');
HOG_Path=fullfile(Data_Path,'hog');
cluster_Path=fullfile(Data_Path,'cluster');
txt_Path=fullfile(Data_Path,'txt');
imgname_Path=fullfile(Data_Path,'imagesname');
pslf_Path=fullfile(Data_Path,'pslf');
label_Path=fullfile(Data_Path,'labels.mat');
stylepatch_Path=fullfile(Data_Path,'style_patch');

%% feature parameters
sample_size=30;
views=12;
pcsize = 48;   %  to accomplish  the calculator of the images HOG .

%% set the percent of the semi-supervised
pectlbs=1;
label_or_constraint=0;

%% calculate number of shapes
FILES_TO_PROCESS        = '*.bmp';
IMGS = dir(fullfile(lines_Path, FILES_TO_PROCESS));
IMGS = {IMGS.name};
Nt=length(IMGS);
models = Nt/views;
%% load style kernel
result_Path=fullfile(pslf_Path,'result.mat');
load(result_Path);
KMname=fullfile(cluster_Path,'kernelModel.mat');
load(KMname);
models = size(kernelModel{1},2);
%% select models in paper
if strcmp(dataname,'hu_car')
    select_model=[1,44,65,68];
elseif strcmp(dataname,'hu_building')
    select_model=[16,26,47,66,86];
elseif strcmp(dataname,'hu_drinkware')
    select_model=[10,26,52];
elseif strcmp(dataname,'hu_furniture')
    select_model=[9,155,397,525];
    K=100;
elseif strcmp(dataname,'hu_leg')
    select_model=[25,38,63];
elseif strcmp(dataname,'our_car')
    select_model=[34,39,63,273,297,319,326,335,340,433,446,721,734,739,948,954];
    K=100;
end
%sty = styw;
%% calculate style localization for all shapes
fprintf('calculate style ...\n');
ikern=0;
for iker=1:views
    ikern=ikern+1;
    
    vname=sprintf('V-%d.mat',iker);
    vcurpath=fullfile(HOG_Path,vname);
    ctname=sprintf('CT-%d.mat',iker);
    ctcurpath=fullfile(HOG_Path,ctname);
    kname=sprintf('kmeans-%d-%d.mat',K,iker);
    kcurpath=fullfile(cluster_Path,kname);
    load(kcurpath);
    load(vcurpath);
    load(ctcurpath);
    
    patchPath=[kernel_Path,'\', num2str(iker),'\ceteridf\'];
    patchName=importdata(fullfile(patchPath,'Apidfpatchname.txt'));
    k2po=importdata([kernel_Path,'\', num2str(iker),'\k2po.txt']);
    Name{ikern,1}=[];
    
    nameT=[];
    for i=1:GK
        patchname=patchName(sty{ikern,i});
        k2p= k2po(sty{ikern,i});
        modelsi=find(labels_best==i);
        modelsi=sort(neworder(modelsi));
        name=[];
         countname=0;
        for j=1:length(k2p)
            for jj=modelsi'
                disbest=inf;
                countname=countname+1;
                for jjj=1:sample_size
                    mn=CT((jj-1)*sample_size+jjj,1);
                    if(mn==0)
                        continue;
                    end
                    dis=sum((V(mn,:)-newceter(k2p(j),:)).^2);
                    if(dis<disbest)
                        disbest=dis;
                        styname=sprintf('%d_%d.bmp',jj,jjj); 
                    end
                end
                name{countname,1}=styname;
           end
        end
        nameT=union(nameT,name);
    end
   
    Name{ikern,1}=union(Name{ikern,1},nameT);
    fprintf('view : %d\n',iker);
end
%% output style localization for selected shapes
fprintf('output style ...\n');
if ~exist(stylepatch_Path,'dir')
    mkdir(stylepatch_Path);
end
fstyle=fopen(fullfile(stylepatch_Path,'style_index.txt'),'w');
select_index=1;
for i=1:models
    if i ~= select_model(select_index)
        continue;
    end
    out_style = zeros(1,sample_size);
    for j=1:sample_size
        pname=sprintf('%d_%d.bmp',i,j);
        count=0;
        for k=1:views            
           [pos,~]=ismember(Name{k,1},pname);
            pos=find(pos==1);
            if~isempty(pos)
                count=count+1;
            end
        end
        out_style(j) = count;
    end
    [unused,index_style] = sort(out_style,'descend');
    pname1=sprintf('%d_%d.bmp',select_index,index_style(1));
    pname2=sprintf('%d_%d.bmp',select_index,index_style(2));
    fprintf(fstyle,'%s\r\n',pname1);
    fprintf(fstyle,'%s\r\n',pname2);
    select_index = select_index+1;
    if select_index > length(select_model)
        break;
    end
end
fclose(fstyle);
end
