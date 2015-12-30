using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.SelfHost;

namespace SqlppService
{
    public partial class Service1 : ServiceBase
    {
        public Service1()
        {
            InitializeComponent();
        }
        HttpSelfHostServer server;
        protected override void OnStart(string[] args)
        {
            try
            {
                var config = new HttpSelfHostConfiguration("http://localhost:8090");

                config.Routes.MapHttpRoute(
                    "API Default", "api/{controller}/{action}");

                server = new HttpSelfHostServer(config);
                server.OpenAsync().Wait();
            } catch (Exception ex)
            {
                EventLog.WriteEntry(ex.ToString());
            }
        }

        protected override void OnStop()
        {
            server.CloseAsync().Wait();
        }
    }
}
