unit mainunit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, ExtCtrls, Process;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Edit1: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label1: TLabel;
    Label4: TLabel;
    LabeledEdit1: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    LabeledEdit3: TLabeledEdit;
    LabeledEdit4: TLabeledEdit;
    LabeledEdit5: TLabeledEdit;
    LabeledEdit6: TLabeledEdit;
    LabeledEdit7: TLabeledEdit;
    ListBox1: TListBox;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    PageControl1: TPageControl;
    Panel1: TPanel;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure GoWay; // выбор пути алгоритма
    procedure LabeledEdit1Exit(Sender: TObject);
    procedure LabeledEdit2Exit(Sender: TObject);
    procedure LabeledEdit3Exit(Sender: TObject);
    procedure LabeledEdit4Exit(Sender: TObject);

    procedure LabeledEdit5Exit(Sender: TObject);
    procedure LabeledEdit6Exit(Sender: TObject);
    procedure LabeledEdit7Exit(Sender: TObject);
    procedure Memo1Exit(Sender: TObject);
    procedure NewRepo; // создать заготовку нового репозитария
    function Getsha(fl: string; index: integer): string; { получить контрольную сумму файла fl
                        index: 1 - md5, 2 - sha1, 3 - sha256    }
    procedure SaveRepo; // сохранить файл описания
    procedure SaveRepoLine(ln: string; index: char); { добавить строку к файлу описания
                      индексы:
                         0 - deb-пакет - 32
                         1 - deb-пакет - 64
                         2 - версия
                         3 - имя пакета
                         4 - секция
                         5 - размер
                         6 - автор
                         7 - сайт
                         8 - описание
                         9 - исходники
                         l - строка подробного описания }
    procedure LoadRepo; // загрузить описание репозитария
    procedure ShowFiles; // показать файлы репозитария в combo
    procedure EnabledAll; // разрешить работу
    procedure ShowRepo; // показать содержание repo
    procedure AddPack(ar: integer; deb: string); // создать описание пакета: 0 - amd64, 1 - i386
    procedure Makegz(filename: string); // создать gz архив файла filename
    procedure Deldeb(ar: string); // удалить пакет deb архитектуры ar ("binary-i386"), если он загружен
    procedure DelSou; // удалить старые исходники, если они были
    procedure AddSou; // добавить в репозитарий описание исходников
    procedure Signature; // добавить цифровую подпись
   private
    { private declarations }
  public
    { public declarations }
  end; 

var
  Form1      : TForm1;
  way        : integer; // переключательнаправлений алгоритма программы
  repName    : string;  // имя текущего репозитария
  home       : string;  // путь к репозитарию
  repo       : tstringlist; // описание репозитария

implementation

{$R *.lfm}

{ TForm1 }

function GetFileSize(flnm: string): integer;
var
  fl2: file of byte;
begin
  assignfile(fl2, flnm);
  reset(fl2);
  result:=FileSize(flnm);
  closefile(fl2);
end;

procedure tform1.EnabledAll;
begin
   groupbox1.Enabled:=true;
   button3.Enabled:=true;
   button6.Enabled:=true;
   button7.Enabled:=true;
   groupbox2.Enabled:=true;
   TabSheet2.Enabled:=true;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  panel1.Visible:=true;
  label1.Caption:='Имя вашего нового репозитария';
  edit1.Caption:='MyNewRepo';
  enabledall;
end;

procedure tform1.Deldeb(ar: string); // удалить пакет deb архитектуры ar ("binary-i386"), если он загружен
var
  flnm  : string;
  i     : integer;
  ch    : char;
begin
  flnm:='';
  if ar='binary-i386' then ch:='1' else ch:='0';
  for i:=0 to repo.Count-1 do
     if repo[i][1]=ch then
       begin
         flnm:=copy(repo[i], 2, length(repo[i]));
         repo[i]:='?';
       end;
  if flnm<>'' then deletefile(flnm);
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  f: textfile;
begin
  SelectDirectoryDialog1.Title:='Укажите папку вашего репозитария';
  if SelectDirectoryDialog1.Execute then
    begin
      assignfile(f, SelectDirectoryDialog1.FileName+'/repo');
      reset(f);
      readln(f, repName);
      closefile(f);
      home:=SelectDirectoryDialog1.FileName+'/'+repname;
      form1.Caption:='MyRepo: '+repName;
    end;
  enabledall;
  loadrepo;
  showrepo;
end;

procedure tform1.ShowRepo;
var
  i: integer;
  s: string;
begin
  memo1.Clear;
  for i:=0 to repo.Count-1 do
     begin
        s:=copy(repo[i], 2, length(repo[i]));
        if repo[i][1]='0' then listbox1.Items.Add(s);
        if repo[i][1]='1' then listbox1.Items.Add(s);
        if repo[i][1]='9' then listbox1.Items.Add(s);
        if repo[i][1]='2' then labelededit1.Text:=s;
        if repo[i][1]='3' then labelededit2.Text:=s;
        if repo[i][1]='4' then labelededit3.Text:=s;
        if repo[i][1]='5' then labelededit4.Text:=s;
        if repo[i][1]='6' then labelededit5.Text:=s;
        if repo[i][1]='8' then labelededit6.Text:=s;
        if repo[i][1]='7' then labelededit7.Text:=s;
        if repo[i][1]='l' then memo1.Lines.Add(s);
     end;
end;


procedure TForm1.Button3Click(Sender: TObject); //добавить пакет
var
  deb: string;
  s  : string;
  i  : integer;
  ar : string;
begin
  opendialog1.Filter:='deb only|*.deb';
  if opendialog1.Execute then
    begin
       if radiobutton1.Checked then ar:='binary-i386' else ar:='binary-amd64';
       s:='';
       if not(DirectoryExists(home+'/ubuntu/dists/dist/universe/'+ar)) then
               createdir(home+'/ubuntu/dists/dist/universe/'+ar);
       for i:=length(opendialog1.FileName) downto 1 do
               if opendialog1.FileName[i]<>'/' then s:=opendialog1.FileName[i]+s else break;
       if not(DirectoryExists(home+'/ubuntu/pool/universe/'+ar)) then
               createdir(home+'/ubuntu/pool/universe/'+ar);
       deb:=home+'/ubuntu/pool/universe/'+ar+'/'+s;
       deldeb(ar); // удалить старый пакет, если он был
       copyfile(opendialog1.FileName,deb,false);
       if radiobutton1.Checked then ar:='1' else ar:='0';
       saverepoline(deb, ar[1]);
       showfiles;
    end;
end;

procedure TForm1.Button6Click(Sender: TObject); //добавить исходники
var
  sou: string;
  s  : string;
  i  : integer;
begin
  opendialog1.Filter:='all files|*';
  if opendialog1.Execute then
    begin
       s:='';
       if not(DirectoryExists(home+'/ubuntu/dists/dist/universe/source')) then
               createdir(home+'/ubuntu/dists/dist/universe/source');
       for i:=length(opendialog1.FileName) downto 1 do
               if opendialog1.FileName[i]<>'/' then s:=opendialog1.FileName[i]+s else break;
       sou:=home+'/ubuntu/dists/dist/universe/source/Sources';
       delsou; // удалить старые исходники, если они были
       copyfile(opendialog1.FileName,sou,false);
       saverepoline(sou, '9');
       showfiles;
    end;
end;

procedure tform1.DelSou;
var
  sr: tSearchRec;
  path: string;
begin
  path:=home+'/ubuntu/dists/dist/universe/sourse';
  if FindFirst(path + '\*.*', faAnyFile, sr) = 0 then
  begin
    repeat
       DeleteFile(path + '\' + sr.name);
    until   FindNext(sr) <> 0;
  end;
  FindClose(sr);
end;


procedure tform1.ShowFiles;
var
  i: integer;
  s: string;
begin
  listbox1.Clear;
  for i:=0 to repo.Count-1 do
     begin
       s:=repo[i][1];
       if s[1] in ['0', '1', '9'] then
         listbox1.Items.Add(copy(repo[i], 2, length(repo[i])));
     end;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  panel1.Visible:=false;
  way:=1;
  goway;
end;


function GetLine(index: char): string;
var
  i: integer;
begin
  result:='';
  for i:=0 to repo.Count-1 do
     if repo[i][1]=index then
       begin
          result:=copy(repo[i], 2, length(repo[i]));
          exit;
       end;
end;


procedure TForm1.Button7Click(Sender: TObject);
var
  i, j : integer;
  s    : string;
  fl   : textfile;
  nm   : string;
begin
  for i:=0 to repo.Count-1 do
     begin
       s:=repo[i];
       if s[1]='1' then addpack(1, s); // пакет i386
       if s[1]='0' then addpack(0, s); // пакет amd64
       if s[1]='9' then addsou; // исходники
     end;
  // главные файлы
  assignfile(fl, home+'/ubuntu/dists/dist/Release');
  rewrite(fl);
  s:='Origin: '+getline('7');             writeln(fl, s);
  s:='Label: Ubuntu';                     writeln(fl, s);
  s:='Suite: stable';                     writeln(fl, s);
  s:='Codename: dist';                    writeln(fl, s);
  s:='Date: '+datetostr(now);             writeln(fl, s);
  s:='';
  for i:=0 to repo.Count-1 do
     begin
       if repo[i][1]='1' then s:=s+' i386';
       if repo[i][1]='0' then s:=s+' amd64';
     end;
  s:='Architectures:'+s;                  writeln(fl, s);
  s:='Components: free';                  writeln(fl, s);
  s:='Description: Repository for '+getline('3'); writeln(fl, s);
  s:='MD5Sum:';                           writeln(fl, s);
  nm:=home+'/ubuntu/dists/dist/universe/binary-i386';
  j:=ansipos('universe/', nm);
  if directoryexists(nm) then
    begin
      s:=' '+getsha(nm+'/Packages', 1)+' '+inttostr(GetFileSize(nm+'/Packages'))+' '+
      copy(nm+'/Packages', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Packages.gz', 1)+' '+inttostr(GetFileSize(nm+'/Packages.gz'))+' '+
      copy(nm+'/Packages.gz', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Release', 1)+' '+inttostr(GetFileSize(nm+'/Release'))+' '+
      copy(nm+'/Release', j, length(nm));    writeln(fl, s);
    end;
  nm:=home+'/ubuntu/dists/dist/universe/binary-amd64';
  if directoryexists(nm) then
    begin
      s:=' '+getsha(nm+'/Packages', 1)+' '+inttostr(GetFileSize(nm+'/Packages'))+' '+
      copy(nm+'/Packages', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Packages.gz', 1)+' '+inttostr(GetFileSize(nm+'/Packages.gz'))+' '+
      copy(nm+'/Packages.gz', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Release', 1)+' '+inttostr(GetFileSize(nm+'/Release'))+' '+
      copy(nm+'/Release', j, length(nm));    writeln(fl, s);
    end;
  nm:=home+'/ubuntu/dists/dist/universe/source';
  if directoryexists(nm) then
    begin
      s:=' '+getsha(nm+'/Sources', 1)+' '+inttostr(GetFileSize(nm+'/Sources'))+' '+
      copy(nm+'/Sources', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Sources.gz', 1)+' '+inttostr(GetFileSize(nm+'/Sources.gz'))+' '+
      copy(nm+'/Sources.gz', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Release', 1)+' '+inttostr(GetFileSize(nm+'/Release'))+' '+
      copy(nm+'/Release', j, length(nm));    writeln(fl, s);
    end;
  s:='SHA1:';                           writeln(fl, s);
  nm:=home+'/ubuntu/dists/dist/universe/binary-i386';
  if directoryexists(nm) then
    begin
      s:=' '+getsha(nm+'/Packages', 2)+' '+inttostr(GetFileSize(nm+'/Packages'))+' '+
      copy(nm+'/Packages', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Packages.gz', 2)+' '+inttostr(GetFileSize(nm+'/Packages.gz'))+' '+
      copy(nm+'/Packages.gz', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Release', 2)+' '+inttostr(GetFileSize(nm+'/Release'))+' '+
      copy(nm+'/Release', j, length(nm));    writeln(fl, s);
    end;
  nm:=home+'/ubuntu/dists/dist/universe/binary-amd64';
  if directoryexists(nm) then
    begin
      s:=' '+getsha(nm+'/Packages', 2)+' '+inttostr(GetFileSize(nm+'/Packages'))+' '+
      copy(nm+'/Packages', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Packages.gz', 2)+' '+inttostr(GetFileSize(nm+'/Packages.gz'))+' '+
      copy(nm+'/Packages.gz', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Release', 2)+' '+inttostr(GetFileSize(nm+'/Release'))+' '+
      copy(nm+'/Release', j, length(nm));    writeln(fl, s);
    end;
  nm:=home+'/ubuntu/dists/dist/universe/source';
  if directoryexists(nm) then
    begin
      s:=' '+getsha(nm+'/Sources', 2)+' '+inttostr(GetFileSize(nm+'/Sources'))+' '+
      copy(nm+'/Sources', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Sources.gz', 2)+' '+inttostr(GetFileSize(nm+'/Sources.gz'))+' '+
      copy(nm+'/Sources.gz', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Release', 2)+' '+inttostr(GetFileSize(nm+'/Release'))+' '+
      copy(nm+'/Release', j, length(nm));    writeln(fl, s);
    end;
  s:='SHA256:';                            writeln(fl, s);
  nm:=home+'/ubuntu/dists/dist/universe/binary-i386';
  if directoryexists(nm) then
    begin
      s:=' '+getsha(nm+'/Packages', 3)+' '+inttostr(GetFileSize(nm+'/Packages'))+' '+
      copy(nm+'/Packages', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Packages.gz', 3)+' '+inttostr(GetFileSize(nm+'/Packages.gz'))+' '+
      copy(nm+'/Packages.gz', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Release', 3)+' '+inttostr(GetFileSize(nm+'/Release'))+' '+
      copy(nm+'/Release', j, length(nm));    writeln(fl, s);
    end;
  nm:=home+'/ubuntu/dists/dist/universe/binary-amd64';
  if directoryexists(nm) then
    begin
      s:=' '+getsha(nm+'/Packages', 3)+' '+inttostr(GetFileSize(nm+'/Packages'))+' '+
      copy(nm+'/Packages', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Packages.gz', 3)+' '+inttostr(GetFileSize(nm+'/Packages.gz'))+' '+
      copy(nm+'/Packages.gz', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Release', 3)+' '+inttostr(GetFileSize(nm+'/Release'))+' '+
      copy(nm+'/Release', j, length(nm));    writeln(fl, s);
    end;
  nm:=home+'/ubuntu/dists/dist/universe/source';
  if directoryexists(nm) then
    begin
      s:=' '+getsha(nm+'/Sources', 3)+' '+inttostr(GetFileSize(nm+'/Sources'))+' '+
      copy(nm+'/Sources', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Sources.gz', 3)+' '+inttostr(GetFileSize(nm+'/Sources.gz'))+' '+
      copy(nm+'/Sources.gz', j, length(nm)); writeln(fl, s);
      s:=' '+getsha(nm+'/Release', 3)+' '+inttostr(GetFileSize(nm+'/Release'))+' '+
      copy(nm+'/Release', j, length(nm));    writeln(fl, s);
    end;
  closefile(fl);
  // подпись
  signature;
  showmessage('Репозитарий создан (обновлен)');
end;


procedure tform1.AddPack(ar: integer; deb: string);
var
  arh, s : string;
  j, k   : integer;
  fl     : textfile;
  flnm   : string;
begin
  arh:='i386';
  if ar=0 then arh:='amd64';
  assignfile(fl, home+'/ubuntu/dists/dist/universe/binary-'+arh+'/Packages');
  rewrite(fl);
  flnm:=copy(deb, 2, length(deb));
  s:='Package: '+getline('3');              writeln(fl, s);
  s:='Priority: optional';                  writeln(fl, s);
  s:='Section: '+getline('4');              writeln(fl, s);
  s:='Installed-Size: '+getline('5');       writeln(fl, s);
  s:='Maintainer: '+getline('6');           writeln(fl, s);
  s:='Original-Maintainer: '+getline('6');  writeln(fl, s);
  s:='Architecture: '+arh;                  writeln(fl, s);
  s:='Source: '+getline('3');               writeln(fl, s);
  s:='Version: '+getline('2');              writeln(fl, s);
  j:=ansipos('pool', flnm); s:=copy(flnm, j, length(flnm));
  s:='Filename: '+s;                        writeln(fl, s);
  s:='Size: '+inttostr(getfilesize(flnm));  writeln(fl, s);
  s:='MD5sum: '+getsha(flnm, 1);            writeln(fl, s);
  s:='SHA1: '+getsha(flnm, 2);              writeln(fl, s);
  s:='SHA256: '+getsha(flnm, 3);            writeln(fl, s);
  s:='Description: '+getline('8');          writeln(fl, s);
  for j:=0 to repo.Count-1 do
     if repo[j][1]='l' then
       begin
         s:=' '+copy(repo[j], 2, length(repo[j]));
         writeln(fl, s);
       end;
  s:=getline('6');
  j:=ansipos('<', s); k:=ansipos('>', s);
  s:=copy(s, j+1, k-j-1);
  s:='Bugs: '+s;                            writeln(fl, s);
  s:='Origin: Ubuntu';                      writeln(fl, s);
  s:='Task: ubuntu-desktop';                writeln(fl, s);
  closefile(fl);
  makegz(home+'/ubuntu/dists/dist/universe/binary-'+arh+'/Packages'); // *.gz
  assignfile(fl, home+'/ubuntu/dists/dist/universe/binary-'+arh+'/Release');
  rewrite(fl);
  s:='Archive: hardy';                      writeln(fl, s);
  s:='Version: '+getline('2');              writeln(fl, s);
  s:='Component: main';                     writeln(fl, s);
  s:='Origin: Ubuntu';                      writeln(fl, s);
  s:='Label: Ubuntu';                       writeln(fl, s);
  s:='Architecture: '+arh;                  writeln(fl, s);
  closefile(fl);
end;

procedure tform1.addsou;
var
  arh, s : string;
  j, k   : integer;
  fl     : textfile;
  flnm   : string;
begin
  makegz(home+'/ubuntu/dists/dist/universe/source/Sources'); // *.gz
  assignfile(fl, home+'/ubuntu/dists/dist/universe/source/Release');
  rewrite(fl);
  s:='Archive: universe';                   writeln(fl, s);
  s:='Version: '+getline('2');              writeln(fl, s);
  s:='Component: main';                     writeln(fl, s);
  s:='Origin: Ubuntu';                      writeln(fl, s);
  s:='Label: Ubuntu';                       writeln(fl, s);
  s:='Architecture: All';                   writeln(fl, s);
  closefile(fl);
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  saverepo;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  panel1.Top:=184;
  panel1.Left:=200;
  repo:=tstringlist.Create;
end;

procedure tform1.GoWay;
begin
  case way of
     1: newrepo;
  end;
end;


procedure TForm1.LabeledEdit1Exit(Sender: TObject);
begin
  saverepoline(labelededit1.Text, '2');
end;

procedure TForm1.LabeledEdit2Exit(Sender: TObject);
begin
  saverepoline(labelededit2.Text, '3');
end;

procedure TForm1.LabeledEdit3Exit(Sender: TObject);
begin
  saverepoline(labelededit3.Text, '4');
end;

procedure TForm1.LabeledEdit4Exit(Sender: TObject);
begin
  saverepoline(labelededit4.Text, '5');
end;


procedure TForm1.LabeledEdit5Exit(Sender: TObject);
begin
  saverepoline(labelededit5.Text, '6');
end;

procedure TForm1.LabeledEdit6Exit(Sender: TObject);
begin
  saverepoline(labelededit6.Text, '8');
end;

procedure TForm1.LabeledEdit7Exit(Sender: TObject);
begin
  saverepoline(labelededit7.Text, '7');
end;

procedure TForm1.Memo1Exit(Sender: TObject);
var
  i   : integer;
  tem : tstringlist;
begin
  tem:=tstringlist.Create;
  for i:=0 to repo.Count-1 do
       if repo[i][1]<>'l' then tem.Add(repo[i]);
  repo.Clear;
  repo:=tem;
  for i:=0 to memo1.Lines.Count-1 do
       repo.Add('l'+memo1.Lines[i]);
end;

procedure tform1.NewRepo;
var
  f: textfile;
begin
  SelectDirectoryDialog1.Title:='Укажите папку для вашего репозитария';
  if SelectDirectoryDialog1.Execute then
    begin
      repName:=edit1.Caption;
      home:=SelectDirectoryDialog1.FileName+'/'+repname;
      createdir(home);
      createdir(home+'/ubuntu');
      createdir(home+'/ubuntu/dists');
      createdir(home+'/ubuntu/pool');
      createdir(home+'/ubuntu/dists/dist');
      createdir(home+'/ubuntu/dists/dist/universe');
      createdir(home+'/ubuntu/pool/universe');
      form1.Caption:='MyRepo: '+repName;
      assignfile(f, SelectDirectoryDialog1.FileName+'/repo');
      rewrite(f);
      writeln(f, repName);
      closefile(f);
    end;
end;

function tform1.Getsha(fl: string; index: integer): string;
var
  AProcess: TProcess;
  AStringList: TStringList;
begin
  AProcess := TProcess.Create(nil);
  AStringList := TStringList.Create;
  case index of
     1: AProcess.CommandLine := 'md5sum '+fl;
     2: AProcess.CommandLine := 'sha1sum '+fl;
     3: AProcess.CommandLine := 'sha256sum '+fl;
     end;
  AProcess.Options := AProcess.Options + [poWaitOnExit, poUsePipes];
  AProcess.Execute;
  AStringList.LoadFromStream(AProcess.Output);
  case index of
     1: result:=copy(astringlist.Text, 1, 32);
     2: result:=copy(astringlist.Text, 1, 40);
     3: result:=copy(astringlist.Text, 1, 64);
   end;
  AStringList.Free;
  AProcess.Free;
end;

procedure tform1.Signature; // подписать репозитарий
var
  flnm       : string;
begin
  flnm:=home+'/ubuntu/dists/dist/Release';
  flnm:='gpg -bao '+flnm+'.gpg '+flnm;
  showmessage('Необходимо подписать репозитарий используя Ваш пароль.' + #13 +
    'Откройте терминал и выполните :' + #13+#13+ flnm+ #13+#13+'(просто скопируйте команду отсюда)' );
end;

procedure tform1.Makegz(fileName: string);
var
  AProcess: TProcess;
begin
  copyfile(filename, filename+'1');
  AProcess := TProcess.Create(nil);
  if fileexists(filename+'.gz') then deletefile(filename+'.gz');
  AProcess.CommandLine := 'gzip '+filename;
  AProcess.Options := AProcess.Options + [poWaitOnExit, poUsePipes];
  AProcess.Execute;
  AProcess.Free;
  RenameFile(filename+'1', filename);
end;


procedure tform1.SaveRepo;
var
  fl: textfile;
  i: integer;
begin
  assignfile(fl, home+'/repo');
  rewrite(fl);
  for i:=0 to repo.Count-1 do
     begin
          if repo[i]<>'?' then writeln(fl, repo[i]);
     end;
  closefile(fl);
end;

procedure tform1.LoadRepo; // загрузить описание
var
  fl: textfile;
  s: string;
begin
  assignfile(fl, home+'/repo');
  reset(fl);
  while not(eof(fl)) do
    begin
       readln(fl, s);
       repo.Add(s);
    end;
  closefile(fl);
end;


procedure tform1.SaveRepoLine(ln: string; index: char);
var
  i: integer;
begin
  if index in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'] then // эти индексы могут быть только в единственном числе
        for i:=0 to repo.Count-1 do if repo[i][1]=index then repo[i]:='?';
  repo.Add(index+ln);
end;

end.

