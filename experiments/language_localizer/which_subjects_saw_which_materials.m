cd Output/

p=pwd;
files=dir([p '/*FED*']);
files={files.name}';

for i = 1:length(files);
    
    f=char(files(i));
    fd=find(f=='_');
    fd2=fd(2);
    fd5=fd(5);
    
    subs(i,1) = {f(fd2+1:fd5-1)};
    
end

usubs=unique(subs);


data_all={};
for i = 1:length(usubs);
    
    sub=char(usubs(i));
    
    fsub=strmatch(sub,subs);
    
    ffiles=files(fsub);
    
    data={};
    
    for j = 1:length(ffiles);
        
        file=char(ffiles(j));
        load(file);
        
        behmat=table2cell(behmat1);
        
        if j == 1;
            
            data(end+1,:)=behmat(1,1:3);
            
        elseif length(intersect(cell2mat(behmat(1,2)),cell2mat(data(:,2))))==0;
            
            data(end+1,:)=behmat(1,1:3);
            
        end
        
    end
    
    szd=size(data);
    
    data_all(end+1:end+szd,:) = {sub};
    data_all(end-szd+1:end,2:3) = data(:,2:3)
    
end
    