FasdUAS 1.101.10   ��   ��    k             p         ������ 0 sshpid sshPid��      	  p       
 
 ������ 0 itsgone itsGone��   	     i         I     ������
�� .aevtoappnull  �   � ****��  ��    k    �       l     ��������  ��  ��        r         I    ��  
�� .sysorpthalis        TEXT  m        �   " b l u e s k y c l i e n t . p u b  �� ��
�� 
in B  l    ����  I   �� ��
�� .earsffdralis        afdr   f    ��  ��  ��  ��    o      ���� 0 adminloc adminLoc      r         n     ! " ! 1    ��
�� 
psxp " o    ���� 0 adminloc adminLoc   o      ���� 0 adminpos adminPos   # $ # l   ��������  ��  ��   $  % & % l   �� ' (��   ' 3 -do we need to turn on SSH and Screen Sharing?    ( � ) ) Z d o   w e   n e e d   t o   t u r n   o n   S S H   a n d   S c r e e n   S h a r i n g ? &  * + * r     , - , I   �� .��
�� .sysoexecTEXT���     TEXT . m     / / � 0 0 @ n e t s t a t   - a n   |   g r e p   ' * . 2 2 ' ; e x i t   0��   - o      ���� 0 sshstate sshState +  1 2 1 r    # 3 4 3 I   !�� 5��
�� .sysoexecTEXT���     TEXT 5 m     6 6 � 7 7 � c a t   / L i b r a r y / P r e f e r e n c e s / c o m . a p p l e . S c r e e n S h a r i n g . l a u n c h d ;   e x i t   0��   4 o      ���� 0 vncstate vncState 2  8 9 8 Z   $ 5 : ;���� : =  $ ' < = < o   $ %���� 0 vncstate vncState = m   % & > > � ? ?   ; r   * 1 @ A @ I  * /�� B��
�� .sysoexecTEXT���     TEXT B m   * + C C � D D X p s   - a x   |   g r e p   A R D A g e n t   |   g r e p   - v   g r e p ; e x i t   0��   A o      ���� 0 vncstate vncState��  ��   9  E F E Z   6 g G H���� G G   6 C I J I l  6 9 K���� K =  6 9 L M L o   6 7���� 0 sshstate sshState M m   7 8 N N � O O  ��  ��   J l  < ? P���� P =  < ? Q R Q o   < =���� 0 vncstate vncState R m   = > S S � T T  ��  ��   H k   F c U U  V W V I  F [�� X Y
�� .sysodlogaskr        TEXT X m   F I Z Z � [ [ � W e   w i l l   n e e d   y o u   t o   t u r n   o n   s o m e   s y s t e m   s e r v i c e s   t o   a l l o w   u s   t o   w o r k .     Y o u r   t e c h   w i l l   w a l k   y o u   t h r o u g h   i t . Y �� \ ]
�� 
btns \ J   L Q ^ ^  _�� _ m   L O ` ` � a a  O K��   ] �� b��
�� 
dflt b m   T U���� ��   W  c�� c I  \ c�� d��
�� .sysoexecTEXT���     TEXT d m   \ _ e e � f f r o p e n   / S y s t e m / L i b r a r y / P r e f e r e n c e P a n e s / S h a r i n g P r e f . p r e f p a n e��  ��  ��  ��   F  g h g l  h h��������  ��  ��   h  i j i l  h h�� k l��   k ' !do we need to look for proxy info    l � m m B d o   w e   n e e d   t o   l o o k   f o r   p r o x y   i n f o j  n o n r   h y p q p n   h u r s r 1   s u��
�� 
psxp s l  h s t���� t I  h s�� u v
�� .earsffdralis        afdr u  f   h i v �� w��
�� 
rtyp w m   l o��
�� 
TEXT��  ��  ��   q o      ���� 0 mypath myPath o  x y x r   z � z { z I  z ��� |��
�� .sysoexecTEXT���     TEXT | b   z � } ~ } b   z �  �  m   z } � � � � �  ' � o   } ����� 0 mypath myPath ~ m   � � � � � � � H / C o n t e n t s / R e s o u r c e s / p r o x y - c o n f i g '   - s��   { o      ���� 0 	proxyconf 	proxyConf y  � � � l  � ���������  ��  ��   �  � � � l  � ��� � ���   �  get my server    � � � �  g e t   m y   s e r v e r �  � � � r   � � � � � I  � ��� ���
�� .sysoexecTEXT���     TEXT � b   � � � � � b   � � � � � m   � � � � � � � 
 c a t   ' � o   � ����� 0 mypath myPath � m   � � � � � � � > / C o n t e n t s / R e s o u r c e s / s e r v e r . t x t '��   � o      ���� 0 
serveraddr 
serverAddr �  � � � l  � ���������  ��  ��   �  � � � l  � ��� � ���   �  will output like this:      � � � � 0 w i l l   o u t p u t   l i k e   t h i s :     �  � � � l  � ��� � ���   �  http://webcache:8080/    � � � � * h t t p : / / w e b c a c h e : 8 0 8 0 / �  � � � Q   � � � ��� � k   � � � �  � � � I  � ��� ���
�� .sysoexecTEXT���     TEXT � m   � � � � � � �  m k d i r   ~ / . s s h��   �  � � � I  � ��� ���
�� .sysoexecTEXT���     TEXT � m   � � � � � � � 0 t o u c h   ~ / . s s h / k n o w n _ h o s t s��   �  ��� � I  � ��� ���
�� .sysoexecTEXT���     TEXT � m   � � � � � � � & t o u c h   ~ / . s s h / c o n f i g��  ��   � R      ������
�� .ascrerr ****      � ****��  ��  ��   �  � � � l  � ���������  ��  ��   �  � � � Q   �s � � � � Z   �N � ��� � � >  � � � � � o   � ����� 0 	proxyconf 	proxyConf � m   � � � � � � �   � k   �D � �  � � � r   � � � � � I  � ��� ���
�� .sysoexecTEXT���     TEXT � m   � � � � � � � B e c h o   $ p r o x y C o n f   |   c u t   - f   3   - d   " / "��   � o      ���� 0 	proxytemp 	proxyTemp �  � � � r   � � � � � I  � ��� ���
�� .sysoexecTEXT���     TEXT � m   � � � � � � � B e c h o   $ p r o x y T e m p   |   c u t   - f   1   - d   " : "��   � o      ���� 0 proxyserver proxyServer �  � � � r   � � � � � I  � ��� ���
�� .sysoexecTEXT���     TEXT � m   � � � � � � � B e c h o   $ p r o x y T e m p   |   c u t   - f   2   - d   " : "��   � o      ���� 0 	proxyport 	proxyPort �  � � � r   � � � � b   � � � � � m   � � � � � � �  - - p r o x y   � o   � ����� 0 	proxyconf 	proxyConf � o      ���� 0 proxycommand proxyCommand �  � � � r   � � � I �� ���
�� .sysoexecTEXT���     TEXT � b   � � � b  
 � � � m   � � � � � 
 g r e p   � o  	���� 0 
serveraddr 
serverAddr � m  
 � � � � � ,   ~ / . s s h / c o n f i g ;   e x i t   0��   � o      ���� 0 knownchk knownChk �  ��� � Z  D � ����� � =  � � � o  ���� 0 knownchk knownChk � m   � � � � �   � k  !@ � �  � � � I !0�� ���
�� .sysoexecTEXT���     TEXT � b  !, � � � b  !( � � � m  !$   �  e c h o   " H o s t   � o  $'���� 0 
serveraddr 
serverAddr � m  (+ � $ "   > >   ~ / . s s h / c o n f i g��   � �� I 1@����
�� .sysoexecTEXT���     TEXT b  1< b  18	 m  14

 � * e c h o   " 	 P r o x y C o m m a n d   '	 o  47���� 0 mypath myPath m  8; � � C o n t e n t s / R e s o u r c e s / c o r k s c r e w '   $ p r o x y S e r v e r   $ p r o x y P o r t   % h   % p "   > >   ~ / . s s h / c o n f i g��  ��  ��  ��  ��  ��   � r  GN m  GJ �   o      ���� 0 proxycommand proxyCommand � R      ���
�� .ascrerr ****      � **** o      �~�~ 0 errstr errStr�   � k  Vs  I Vm�}
�} .sysodlogaskr        TEXT b  V[ m  VY � | P l e a s e   t e l l   y o u r   t e c h   t h a t   t h e r e   w a s   a   c o n f i g u r a t i o n   f a i l u r e :   o  YZ�|�| 0 errstr errStr �{
�{ 
btns J  ^c �z m  ^a   �!!  Q u i t�z   �y"�x
�y 
dflt" m  fg�w�w �x   #�v# I ns�u�t�s
�u .aevtquitnull��� ��� null�t  �s  �v   � $%$ l tt�r�q�p�r  �q  �p  % &'& Q  t�()�o( k  w�** +,+ I w~�n-�m
�n .sysoexecTEXT���     TEXT- m  wz.. �// 0 r m   - f   ~ / . s s h / b l u e s k y _ t m p�m  , 0�l0 I ��k1�j
�k .sysoexecTEXT���     TEXT1 m  �22 �33 8 r m   - f   ~ / . s s h / b l u e s k y _ t m p . p u b�j  �l  ) R      �i�h�g
�i .ascrerr ****      � ****�h  �g  �o  ' 454 l ���f�e�d�f  �e  �d  5 676 Q  ��89:8 I ���c;�b
�c .sysoexecTEXT���     TEXT; m  ��<< �== � s s h - k e y g e n   - q   - t   s s h - e d 2 5 5 1 9   - N   " "   - f   ~ / . s s h / b l u e s k y _ t m p   - C   " t m p - ` d a t e   + % s ` "�b  9 R      �a>�`
�a .ascrerr ****      � ****> o      �_�_ 0 errstr errStr�`  : k  ��?? @A@ I ���^BC
�^ .sysodlogaskr        TEXTB b  ��DED m  ��FF �GG h P l e a s e   t e l l   y o u r   t e c h   t h a t   t h e r e   w a s   a   k e y   f a i l u r e :  E o  ���]�] 0 errstr errStrC �\HI
�\ 
btnsH J  ��JJ K�[K m  ��LL �MM  Q u i t�[  I �ZN�Y
�Z 
dfltN m  ���X�X �Y  A O�WO I ���V�U�T
�V .aevtquitnull��� ��� null�U  �T  �W  7 PQP l ���S�R�Q�S  �R  �Q  Q RSR r  ��TUT I ���PV�O
�P .sysoexecTEXT���     TEXTV b  ��WXW b  ��YZY b  ��[\[ b  ��]^] b  ��_`_ b  ��aba m  ��cc �dd � p u b K e y = ` o p e n s s l   s m i m e   - e n c r y p t   - a e s 2 5 6   - i n   ~ / . s s h / b l u e s k y _ t m p . p u b   - o u t f o r m   P E M  b l ��e�N�Me n  ��fgf 1  ���L
�L 
strqg o  ���K�K 0 adminpos adminPos�N  �M  ` m  ��hh �ii  ` ; c u r l  ^ o  ���J�J 0 proxycommand proxyCommand\ m  ��jj �kk �   - s   - S   - m   6 0   - 1   - - r e t r y   4   - X   P O S T   - - d a t a - u r l e n c o d e   " n e w p u b = $ p u b K e y "   h t t p s : / /Z o  ���I�I 0 
serveraddr 
serverAddrX m  ��ll �mm , / c g i - b i n / c o l l e c t o r . p h p�O  U o      �H�H 0 uploadresult uploadResultS non Z  �pq�G�Fp H  ��rr E  ��sts o  ���E�E 0 uploadresult uploadResultt m  ��uu �vv  I n s t a l l e dq k  �ww xyx I �
�Dz{
�D .sysodlogaskr        TEXTz b  ��|}| m  ��~~ � p P l e a s e   t e l l   y o u r   t e c h   t h a t   t h e r e   w a s   a n   u p l o a d   f a i l u r e :  } o  ���C�C 0 uploadresult uploadResult{ �B��
�B 
btns� J  � �� ��A� m  ���� ���  Q u i t�A  � �@��?
�@ 
dflt� m  �>�> �?  y ��=� I �<�;�:
�< .aevtquitnull��� ��� null�;  �:  �=  �G  �F  o ��� l �9�8�7�9  �8  �7  � ��� I �6��5
�6 .sysodelanull��� ��� nmbr� m  �4�4 �5  � ��� l �3���3  �  pick a random port   � ��� $ p i c k   a   r a n d o m   p o r t� ��� r  2��� I .�2�1�
�2 .sysorandnmbr    ��� nmbr�1  � �0��
�0 
from� m  "�/�/�� �.��-
�. 
to  � m  %(�,�,��-  � o      �+�+ 0 portnum portNum� ��� r  3>��� l 3:��*�)� [  3:��� m  36�(�(U�� o  69�'�' 0 portnum portNum�*  �)  � o      �&�& 0 sshport sshPort� ��� r  ?J��� l ?F��%�$� [  ?F��� m  ?B�#�#]�� o  BE�"�" 0 portnum portNum�%  �$  � o      �!�! 0 vncport vncPort� ��� l KK� ���   �  �  � ��� I Kj���
� .sysoexecTEXT���     TEXT� b  Kf��� b  Kb��� b  K^��� b  KZ��� b  KV��� b  KR��� m  KN�� ���� s s h   - o   S t r i c t H o s t K e y C h e c k i n g = n o   - c   c h a c h a 2 0 - p o l y 1 3 0 5 @ o p e n s s h . c o m   - o   H o s t K e y A l g o r i t h m s = s s h - e d 2 5 5 1 9   - m   h m a c - s h a 2 - 5 1 2 - e t m @ o p e n s s h . c o m   - o   K e x A l g o r i t h m s = c u r v e 2 5 5 1 9 - s h a 2 5 6 @ l i b s s h . o r g   - i   ~ / . s s h / b l u e s k y _ t m p   - n N T   - R  � o  NQ�� 0 sshport sshPort� m  RU�� ��� " : l o c a l h o s t : 2 2   - R  � o  VY�� 0 vncport vncPort� m  Z]�� ��� @ : l o c a l h o s t : 5 9 0 0   - p   3 1 2 2   b l u e s k y @� o  ^a�� 0 
serveraddr 
serverAddr� m  be�� ��� .   & >   / d e v / n u l l   &   e c h o   $ !�  � ��� r  kr��� l kn���� 1  kn�
� 
rslt�  �  � o      �� 0 sshpid sshPid� ��� Q  s����� k  v��� ��� I v{���
� .sysodelanull��� ��� nmbr� m  vw�� �  � ��� I |����
� .sysoexecTEXT���     TEXT� b  |���� b  |���� m  |�� ���  p s   - p  � o  ��� 0 sshpid sshPid� m  ���� ���    |   g r e p   s s h�  � ��� r  ����� m  ���
� boovfals� o      �� 0 itsgone itsGone� ��� I �����
� .sysodlogaskr        TEXT� b  ����� b  ����� m  ���� ��� < Y o u   a r e   n o w   c o n n e c t e d   w i t h   I D  � o  ���
�
 0 portnum portNum� m  ���� ��� < .   Q u i t   t h i s   a p p   t o   d i s c o n n e c t .� �	��
�	 
btns� J  ���� ��� m  ���� ���  O K�  � ���
� 
givu� m  ���� �  �  � R      ���
� .ascrerr ****      � ****�  �  � k  ���� ��� I �����
� .sysodlogaskr        TEXT� m  ���� ��� Z P l e a s e   t e l l   y o u r   t e c h   t h a t   c o n n e c t i n g   f a i l e d .� � ��
�  
btns� J  ���� ���� m  ���� ���  Q u i t��  � �����
�� 
dflt� m  ������ ��  � ���� I ��������
�� .aevtquitnull��� ��� null��  ��  ��  � ���� l ����������  ��  ��  ��       l     ��������  ��  ��    i     I     ������
�� .miscidlenmbr    ��� null��  ��   k     2  Q     /	
	 I   ����
�� .sysoexecTEXT���     TEXT b     b     m     �  p s   - p   o    ���� 0 sshpid sshPid m     �    |   g r e p   s s h��  
 R      ������
�� .ascrerr ****      � ****��  ��   k    /  Z    )���� >    o    ���� 0 itsgone itsGone m    ��
�� boovtrue I   %��
�� .sysodlogaskr        TEXT m     � N T h e   c o n n e c t i o n   h a s   b e c o m e   d i s c o n n e c t e d . �� !
�� 
btns  J    "" #��# m    $$ �%%  Q u i t��  ! ��&��
�� 
dflt& m     !���� ��  ��  ��   '��' I  * /������
�� .aevtquitnull��� ��� null��  ��  ��   (��( L   0 2)) m   0 1���� ��   *+* l     ��������  ��  ��  + ,-, i    ./. I     ������
�� .aevtquitnull��� ��� null��  ��  / k     900 121 Q     34��3 I   
��5��
�� .sysoexecTEXT���     TEXT5 b    676 m    88 �99  k i l l   - 9  7 o    ���� 0 sshpid sshPid��  4 R      ������
�� .ascrerr ****      � ****��  ��  ��  2 :;: Q    +<=��< k    ">> ?@? I   ��A��
�� .sysoexecTEXT���     TEXTA m    BB �CC 0 r m   - f   ~ / . s s h / b l u e s k y _ t m p��  @ D��D I   "��E��
�� .sysoexecTEXT���     TEXTE m    FF �GG 8 r m   - f   ~ / . s s h / b l u e s k y _ t m p . p u b��  ��  = R      ������
�� .ascrerr ****      � ****��  ��  ��  ; HIH r   , /JKJ m   , -��
�� boovtrueK o      ���� 0 itsgone itsGoneI LML M   0 7NN I     ������
�� .aevtquitnull��� ��� null��  ��  M O��O l  8 8��������  ��  ��  ��  - P��P l     ��������  ��  ��  ��       ��QRSTUVWXYZ��������  Q ������������������������
�� .aevtoappnull  �   � ****
�� .miscidlenmbr    ��� null
�� .aevtquitnull��� ��� null�� 0 adminloc adminLoc�� 0 adminpos adminPos�� 0 sshstate sshState�� 0 vncstate vncState�� 0 mypath myPath�� 0 	proxyconf 	proxyConf�� 0 itsgone itsGone��  ��  R �� ����[\��
�� .aevtoappnull  �   � ****��  ��  [ ���� 0 errstr errStr\ e ������������ /���� 6�� > C N S�� Z�� `������ e������ � ��� � ��� � � ����� � ��� ��� ��� ��� � ��� � 
�� ��.2<FLc��hjl��u~�������~�}�|�{�z�y�x�w�����v�u���t����s�r��
�� 
in B
�� .earsffdralis        afdr
�� .sysorpthalis        TEXT�� 0 adminloc adminLoc
�� 
psxp�� 0 adminpos adminPos
�� .sysoexecTEXT���     TEXT�� 0 sshstate sshState�� 0 vncstate vncState
�� 
bool
�� 
btns
�� 
dflt�� 
�� .sysodlogaskr        TEXT
�� 
rtyp
�� 
TEXT�� 0 mypath myPath�� 0 	proxyconf 	proxyConf�� 0 
serveraddr 
serverAddr��  ��  �� 0 	proxytemp 	proxyTemp�� 0 proxyserver proxyServer�� 0 	proxyport 	proxyPort�� 0 proxycommand proxyCommand�� 0 knownchk knownChk�� 0 errstr errStr
�� .aevtquitnull��� ��� null
�� 
strq�� 0 uploadresult uploadResult
�� .sysodelanull��� ��� nmbr
�� 
from��
�~ 
to  �}�
�| .sysorandnmbr    ��� nmbr�{ 0 portnum portNum�zU��y 0 sshport sshPort�x]��w 0 vncport vncPort
�v 
rslt�u 0 sshpid sshPid�t 0 itsgone itsGone
�s 
givu�r �����)j l E�O��,E�O�j E�O�j E�O��  �j E�Y hO�� 
 	�� a & "a a a kva ka  Oa j Y hO)a a l �,E` Oa _ %a %j E` Oa _ %a %j E`  O a !j Oa "j Oa #j W X $ %hO �_ a & va 'j E` (Oa )j E` *Oa +j E` ,Oa -_ %E` .Oa /_  %a 0%j E` 1O_ 1a 2  $a 3_  %a 4%j Oa 5_ %a 6%j Y hY 	a 7E` .W $X 8 %a 9�%a a :kva ka  O*j ;O a <j Oa =j W X $ %hO a >j W $X 8 %a ?�%a a @kva ka  O*j ;Oa A�a B,%a C%_ .%a D%_  %a E%j E` FO_ Fa G $a H_ F%a a Ikva ka  O*j ;Y hOlj JO*a Ka La Ma Na  OE` POa Q_ PE` ROa S_ PE` TOa U_ R%a V%_ T%a W%_  %a X%j O_ YE` ZO @lj JOa [_ Z%a \%j OfE` ]Oa ^_ P%a _%a a `kva aa ba  W "X $ %a ca a dkva ka  O*j ;OPS �q�p�o]^�n
�q .miscidlenmbr    ��� null�p  �o  ]  ^ �m�l�k�j�i�h$�g�f�e�d�c�m 0 sshpid sshPid
�l .sysoexecTEXT���     TEXT�k  �j  �i 0 itsgone itsGone
�h 
btns
�g 
dflt�f 
�e .sysodlogaskr        TEXT
�d .aevtquitnull��� ��� null�c �n 3 ��%�%j W "X  �e ���kv�k� Y hO*j O�T �b/�a�`_`�_
�b .aevtquitnull��� ��� null�a  �`  _  ` 	8�^�]�\�[BF�Z�Y�^ 0 sshpid sshPid
�] .sysoexecTEXT���     TEXT�\  �[  �Z 0 itsgone itsGone
�Y .aevtquitnull��� ��� null�_ : ��%j W X  hO �j O�j W X  hOeE�O)jd* OPUalis       sphenHD                    �ߘLH+  ���blueskyclient.pub                                              �		�=�P        ����  	                	Resources     ��ޜ      �>2�     ����������߿��q c� �= ,  usphenHD:Users: sphen: src: BlueSky: Admin Tools: BlueSky Temporary Client.app: Contents: Resources: blueskyclient.pub   $  b l u e s k y c l i e n t . p u b    s p h e n H D  eUsers/sphen/src/BlueSky/Admin Tools/BlueSky Temporary Client.app/Contents/Resources/blueskyclient.pub   /    ��  V �aa � / U s e r s / s p h e n / s r c / B l u e S k y / A d m i n   T o o l s / B l u e S k y   T e m p o r a r y   C l i e n t . a p p / C o n t e n t s / R e s o u r c e s / b l u e s k y c l i e n t . p u bW �bb: t c p 4               0             0     * . 2 2                                       * . *                                         L I S T E N            t c p 6               0             0     * . 2 2                                       * . *                                         L I S T E N          X �cc �     5 9 7   ? ?                   0 : 1 7 . 1 9   / S y s t e m / L i b r a r y / C o r e S e r v i c e s / R e m o t e M a n a g e m e n t / A R D A g e n t . a p p / C o n t e n t s / M a c O S / A R D A g e n tY �dd � / U s e r s / s p h e n / s r c / B l u e S k y / A d m i n   T o o l s / B l u e S k y   T e m p o r a r y   C l i e n t . a p p /Z �ee  
�� boovtrue��  ��  ascr  ��ޭ