unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, ExtCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Edit1: TEdit;
    Label1: TLabel;
    PageControl1: TPageControl;
    Panel1: TPanel;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    TabSheet1: TTabSheet;
    procedure Button1Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure CreateRep; // создать репозитарий
    procedure SelectWay; // Управление действием
    procedure ShowTree; // отобразить дерево репозитария
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  Form1      : TForm1;
  way        : integer; // указатель для ветвления алгоритма программы
  repName    : string;  // имя репозитария

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
// создать новый репозитарий
begin
  label1.Caption:='Имя вашего нового репозитария:';
  edit1.Caption:='MyRep';
  way:=1;
  panel1.Visible:=true;
end;

procedure TForm1.Button6Click(Sender: TObject);   // ок панели запроса
begin
  panel1.Visible:=false;
  selectway
end;


procedure tform1.SelectWay;
begin
  case way of
    1: createrep;
  end;
end;

procedure tform1.CreateRep; // сoздать репозитарий
var
  rep: string;
begin
  SelectDirectoryDialog1.Title:='Папка для вашего репозитария';
  if SelectDirectoryDialog1.Execute then
    begin
      repName:=edit1.caption;
      rep:=SelectDirectoryDialog1.FileName+repName;
      createdir(rep);
      {
      здесь создать основу структуры репозитария (дерево папок)
      }
      showtree; // отобразить дерево репозитария
    end;
end;

procedure tform1.ShowTree;
begin
  //treeview1.Items.Clear; // clear tree
  //treeview1.Items.Add(nil, 'repName'); // верхний узел

end;

end.
