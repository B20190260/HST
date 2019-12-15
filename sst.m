function [Tx,t,f,xMean,InstantFreq] = sst(x , fs,  WindowOpt, Parameter, Mode)
%	------------------- ͬ��ѹ�� -------------------- 
%Input:
%       Wx:С���任ϵ��
%       InstantFreq:���任ʱȥ����ƽ��ֵ
%       fs:����Ƶ�ʣ�Hz��
%       WindowOpt:������ѡ�����
%           WindowOpt.s��(0.01) ��������ʼ�߶�
%           WindowOpt.f0��(0) ��������ʼ����Ƶ��
%           WindowOpt.type��(gauss) ����������
%       Parameter:Ƶ��ѡ�����
%           Parameter.L��(200) Ƶ�ʻ��ָ���
%           Parameter.fmin��(��С�ֱ���) ������СƵ��
%           Parameter.fmax��(�ο�˹��Ƶ��) �������Ƶ��
%Output:
%       Tx:SSTϵ��
%       fm:ѹ�����Ƶ�ʣ�Hz��
%---------------------------------------------------------------------------------
%    Synchrosqueezing Toolbox
%    Authors: ���ܽܣ�2019/1/13��
%---------------------------------------------------------------------------------
%% Ԥ�����ź�
    N = length(x);
%% ������ֵ
    s = WindowOpt.s; type = WindowOpt.type;
    L = Parameter.L; fmin = Parameter.fmin; fmax = Parameter.fmax;
    gamma = sqrt(eps); 
%% SST����
    %STFT����
    [Wx,t,f,xMean] = stft(x, fs, WindowOpt, Parameter, 'modify');
    %˲ʱƵ�ʼ���
    if strcmp(Mode, '1Ord')
        WindowOpt.type = '1ord(t)_gauss';
        [dWx,~,~,~] = stft(x, fs, WindowOpt, Parameter, 'modify');
        InstantFreq = -imag(dWx./Wx)/2/pi;
        for ptr = 1:L
            InstantFreq(ptr,:) = InstantFreq(ptr,:) + f(ptr);
        end
        InstantFreq( abs(Wx) < gamma ) = Inf;
    elseif strcmp(Mode, '2Ord')
        WindowOpt.type = '1ord(t)_gauss';
        [dWx,~,~,~] = stft(x, fs, WindowOpt, Parameter, 'modify');
        WindowOpt.type = '2ord(t)_gauss';
        [ddWx,~,~,~] = stft(x, fs, WindowOpt, Parameter, 'modify');
        WindowOpt.type = 't*gauss';
        [tWx,~,~,~] = stft(x, fs, WindowOpt, Parameter, 'modify');
        WindowOpt.type = 't*1ord(t)_gauss';
        [tdWx,~,~,~] = stft(x, fs, WindowOpt, Parameter, 'modify');
        Denominator = tdWx.*Wx-tWx.*dWx;
        Numerator = ddWx.*tWx-dWx.*tdWx;
        p = Numerator./Denominator;
        for ptr = 1:L
            p(ptr,:) = p(ptr,:) + 1i*f(ptr)*2*pi;
        end
        InstantFreq = imag(p)/2/pi;
        InstantFreq( abs(Denominator) < gamma ) = Inf;
    else
        error('Unknown SST Mode: %s', Mode);
    end
    %Ƶ�ʲ�ּ���
    df = f(2)-f(1);
    %��ʱ������
    [~,gt] = windowf(s,type);
    %����g(0)
    g0 = gt(0);
    if(g0 == 0)
        error('window must be non-zero and continuous at 0 !');
    end
    %ͬ��ѹ��
    Wx(isinf(InstantFreq)) = 0;
    Tx = zeros(L,N);
    for b=1:N
       for prt=1:L
            k = min(max(1 + round((InstantFreq(prt,b)-fmin)/df),1),L);
            Tx(k, b) = Tx(k, b) + Wx(prt, b) * df;
        end
    end
    Tx = Tx / g0;
end
