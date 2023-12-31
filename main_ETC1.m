clear all
close all

rng('shuffle')

global J k1 delta sigma 

J=[1 -1 0; -1 5 0; 0 0 7];
k1=2;
delta=0.01*k1;%(0,4k1)
sigma=0.1;%(0,1)

% q_0=[1;0;0;0];
% o_0=[0;0;0];
% h_0=1;
% hu_0=[0;0;0];

%can have complete discrete sol
q_0=-[1;0;0;0];
o_0=[0;0;0];
h_0=1;
hu_0=[0;0;0];

% %can have complete discrete sol
% aux=[2;9;-7;2];
% q_0=aux./norm(aux);
% o_0=[0;0;0];
% h_0=1;
% hu_0=[0;0;0];

xi_0=[q_0;o_0;h_0;hu_0];

TSPAN = [0 100];
JSPAN = [0 100];
rule  = 1;%1 for jumps

options = odeset('AbsTol',1e-6,'RelTol',1e-3,'InitialStep',eps);
    
[t,j,xi] = HyEQsolver(@F,@G,@C,@D,xi_0,TSPAN,JSPAN,rule,options);

save data_ETC

%q(1)-h vs 0
%o vs 0
n_vec=xi(:,1);
q_vec=xi(:,1:4);
o_vec=xi(:,5:7);
h_vec=xi(:,8);
hu_vec=xi(:,9:11);
q1_vec=xi(:,1);
figure(1)
plot(t,abs(q1_vec-h_vec))
set(gca, 'YScale', 'log')
figure(2)
plot(t,sum(o_vec.^2,2).^(0.5))
set(gca, 'YScale', 'log')
figure(3)
plot(t,h_vec)
set(gca, 'YScale', 'linear')
figure(4)
plot(t,hu_vec)
set(gca, 'YScale', 'linear')

%check ETC
D_etc=zeros(length(t),1);
D_syner=zeros(length(t),1);
for i=1:1:length(t)
    aux=transpose(xi(i,:));
    gradV=fcn_gradV(aux);
    f=F(aux);
    W=fcn_W(aux);
    D_etc(i)=(gradV'*f>=sigma*W);
    D_syner(i)=(fcn_mu(aux)>=delta);
end

% %check if in A_xi={V(z)\leq\eigmax(P)*c^2} eventually====>plot V(z) and the line \eigmax(P)*c^2
% V_vec=zeros(length(t),1);
% for i=1:1:length(t)
%     V_vec(i)=fcn_V(transpose(xi(i,:)));
% end
% c=1/theta*(min(eigs(K)))^(-1)*alpha*norm(delta);
% plot(t,V_vec,t,max(eigs(P))*c^2.*ones(length(t),1))
% set(gca, 'YScale', 'log')

save("data_ETC","n_vec","q_vec","o_vec","h_vec","hu_vec","D_etc","-append")

function dxi = F(xi)
    global J k1 delta sigma
    q=xi(1:4);
    o=xi(5:7);
    h=xi(8);
    hu=xi(9:11);
    
    u=hu;
    
    dq=1/2.*fcn_E(q)*o;
    do=J\(fcn_S(J*o)*o+u);
    dh=0;
    dhu=[0;0;0];
    dxi = [dq;do;dh;dhu];
end

function next_xi = G(xi)
    global J k1 delta sigma
    q=xi(1:4);
    o=xi(5:7);
    h=xi(8);
    hu=xi(9:11);
    
    gradV=fcn_gradV(xi);
    f=F(xi);
    W=fcn_W(xi);
    
    D_syner=(fcn_mu(xi)>=delta);
    next_syner=[q;o;-h;hu];
    
    D_etc=(gradV'*f>=sigma*W);
    next_etc=[q;o;h;fcn_kappa([q;o;h])];
    
    I2=round(1+rand(1,1));%1 or 2
    next_syner_etc=[next_syner next_etc];
    
    if (D_syner==1)&&(D_etc==0)
        next_xi = next_syner;
    elseif (D_syner==0)&&(D_etc==1)
        next_xi = next_etc;
    else
        next_xi = next_syner_etc(:,2);%to check if ETC can issue complete discrete sols, change I2 to 2
    end
end

function out = C(xi)
    global J k1 delta sigma
    
    gradV=fcn_gradV(xi);
    f=F(xi);
    W=fcn_W(xi);
    
    out = (fcn_mu(xi)<=delta)&(gradV'*f<=sigma*W);
end

function out = D(xi)
    global J k1 delta sigma
    
    gradV=fcn_gradV(xi);
    f=F(xi);
    W=fcn_W(xi);
    
    out = (fcn_mu(xi)>=delta)|(gradV'*f>=sigma*W);
end

function out=fcn_kappa(in)
    global J k1 delta sigma
    q=in(1:4);
    o=in(5:7);
    h=in(8);
    
    out=-k1.*h.*q(2:4)-o;%theta(o)
end

function out=fcn_mu(in)
    global J k1 delta sigma
    q=in(1:4);
    o=in(5:7);
    h=in(8);
    
    x1=in;
    x2=[q;o;-h];
    
    out=fcn_V(x1)-min(fcn_V(x1),fcn_V(x2));
end

function out=fcn_R(q)
    out=quat2rotm(q');
end

function out=fcn_E(q)
    n=q(1);
    e=q(2:4);
    out=[-e';n*eye(3)+fcn_S(e)];
end

function out=fcn_S(x)
    out=[0 -x(3) x(2);...
        x(3) 0 -x(1);...
        -x(2) x(1) 0];
end

function out=fcn_V(in)
    global J k1 delta sigma
    q=in(1:4);
    o=in(5:7);
    h=in(8);
    
    out=2*k1*(1-h*q(1))+1/2.*o'*J*o;
end

function out=fcn_gradV(in)
    global J k1 delta sigma
    q=in(1:4);
    o=in(5:7);
    h=in(8);
    
    out=[-2.*k1.*h.*[1;0;0;0];J*o;0;zeros(3,1)];
end

function out=fcn_W(in)
    global J k1 delta sigma
    q=in(1:4);
    o=in(5:7);
    h=in(8);
    
    out=-o'*o;%theta(o)
end
