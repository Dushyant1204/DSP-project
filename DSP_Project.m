clc;
clear all
close all
disp('Process start....');
%Image reading
[FILENAME PATHNAME]=uigetfile('*.jpeg','Select the finger image');
FilePath=strcat(PATHNAME,FILENAME);
disp('The Image file location is');
disp(FilePath);
[DataImg,map]=imread(FilePath);
figure
imshow(DataImg,map);
title('original image');
%%
%Calculating height and width of picture
[ImH ImW Cdata]=size(DataImg);
if(Cdata==3)
    DataImg=rgb2gray(DataImg);
end
disp('Height')
disp(ImH);
disp('Width');
disp(ImW);
%Image pre processing stage
I=DataImg;
%Canny Edge===Cropped and resized
[~, threshold]=edge(I, 'Canny');  %returns threshold as 2 element vector
fudgeFactor=.5;  %taken to arrive at expected solution
Cedge=edge(I,'Canny', threshold*fudgeFactor);  %specifies sensitivity thresholds
figure, imshow(Cedge)
title('Edge Detection (Canny)');
se90=strel('line',3,90);
se0=strel('line',3,0);
Cedgedil=imdilate(Cedge,[se90 se0]);
figure,imshow(Cedgedil),title('Dilated Edge mask');
Cedgefill=imfill(Cedgedil,'holes');
figure,imshow(Cedgefill);
title('Dilated edge with filled holes');
%%
%Extracting the largest connected components
B=strel('square',15);
A=Cedgefill;
CC=bwconncomp(A);
numPixels=cellfun(@numel,CC.PixelIdxList);
[bigges, idx]=max(numPixels);
I(CC.PixelIdxList{idx})=0;
%Thresholding
Dfinal=zeros(ImH,ImW);
for i=1:ImH
    for j=1:ImW
        if(I(i,j)==0)
            Dfinal(i,j)=DataImg(i,j);
        else 
            Dfinal(i,j)=0;
        end
    end
end
figure, imshow(uint8(Dfinal));
title('Largest Connected Component');
[Ilabel num]=bwlabel(Dfinal);
Iprops=regionprops(Ilabel);
Ibox=[Iprops.BoundingBox];
Icrop=imcrop(DataImg,Ibox);
Icropsize=imresize(Icrop,[ImH,ImW]);
figure,imshow(uint8(Icropsize));
title('Cropped and resized image');
%Noise Reduction
FiltereImg=medfilt2(Icropsize);
figure,imshow(uint8(FiltereImg));
title('After-Median Filtering');
%Histogram equalization
EnhancedImg=histeq(FiltereImg);
figure,imshow(uint8(EnhancedImg));
title('After histogram equalization');
%Coherence Computation
M=3;
R=M-1;
Input_Im=double(EnhancedImg);
row_max=size(Input_Im,1)-M+1;
col_max=size(Input_Im,2)-M+1;
Data_Im=zeros(row_max+R,col_max+R);
for i=1:row_max
    for j=1:col_max
        %contrast saliency measure
        A=Input_Im(i:i+M-1, j:j+M-1);
        [U,W,V]=svd(A);
        w1=W(1,1);
        w2=W(2,2);
        w3=W(3,3);
        C=w1-(w2+w3);
        Data_Im(i,j)=C;
    end
end
figure,imshow(uint8(Data_Im));
title('Coherence Computation');

%LCP
M=3;
C=round(M/2);
Coh_Im=double(Data_Im);
row_max=size(Input_Im,1)-M+1;
col_max=size(Input_Im,2)-M+1;
LCP_Im=zeros(row_max,col_max);
for i=1:row_max
    for j=1:col_max
        %LCP
        A1=Coh_Im(i:i+M-1, j:j+M-1);
        Cdata=A1(C,C);
        Cdata1=A1(1,2);Cdata2=A1(1,3);Cdata3=A1(2,3);Cdata4=A1(3,3);
        Cdata5=A1(3,2);Cdata6=A1(3,1);Cdata7=A1(2,1);Cdata8=A1(1,1);
        if(Cdata>Cdata1)
            B1=1; else B1=0;
        end
        if(Cdata>Cdata2)
            B2=1; else B2=0;
        end
        if(Cdata>Cdata3)
            B3=1; else B3=0;
        end
        if(Cdata>Cdata4)
            B4=1; else B4=0;
        end
        if(Cdata>Cdata5)
            B5=1; else B5=0;
        end
        if(Cdata>Cdata6)
            B6=1; else B6=0;
        end
        if(Cdata>Cdata7)
            B7=1; else B7=0;
        end
        if(Cdata>Cdata8)
            B8=1; else B8=0;
        end
    LCP_Im(i,j)=B1 + B2*2 + B3*4 + B4*8 +B5*16 + B6*32 + B7*64 + B8*128;
    end
end
figure, imshow(uint8(LCP_Im));
title('Local Coherence Pattern');
bins=2^8;
histLCP_Im=hist(LCP_Im(:),0:(bins-1));
figure,stem(histLCP_Im)
title('Feature Vector_LBP');
xlabel('No. of feature');
ylabel('Feature Vector');
