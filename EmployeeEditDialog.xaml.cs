using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;

namespace SalesManagementSystem
{
    public partial class EmployeeEditDialog : Window
    {
        public string EmployeeName => NameBox.Text.Trim();
        public string EmployeePhone => PhoneBox.Text.Trim();
        public string EmployeeEmail => EmailBox.Text.Trim();
        public string EmployeePosition => PositionBox.Text.Trim();

        public EmployeeEditDialog(string name, string phone, string email, string position)
        {
            InitializeComponent();
            NameBox.Text = name;
            PhoneBox.Text = phone;
            EmailBox.Text = email;
            PositionBox.Text = position;
            NameBox.Focus();
        }

        private void Ok_Click(object sender, RoutedEventArgs e)
        {
            if (string.IsNullOrWhiteSpace(NameBox.Text) || string.IsNullOrWhiteSpace(PositionBox.Text))
            {
                MessageBox.Show("ПІБ та посада не можуть бути порожніми.", "Помилка", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }
            DialogResult = true;
        }
    }
}
