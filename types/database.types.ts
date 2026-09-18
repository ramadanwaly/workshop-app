export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  app_private: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      current_user_role: { Args: never; Returns: string }
      is_owner: { Args: never; Returns: boolean }
      is_staff: { Args: never; Returns: boolean }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      audit_log: {
        Row: {
          action: string
          actor_id: string | null
          created_at: string
          details: Json
          entity_id: string | null
          entity_table: string
          id: string
          occurred_at: string
          reason: string | null
          updated_at: string
        }
        Insert: {
          action: string
          actor_id?: string | null
          created_at?: string
          details?: Json
          entity_id?: string | null
          entity_table: string
          id?: string
          occurred_at?: string
          reason?: string | null
          updated_at?: string
        }
        Update: {
          action?: string
          actor_id?: string | null
          created_at?: string
          details?: Json
          entity_id?: string | null
          entity_table?: string
          id?: string
          occurred_at?: string
          reason?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "audit_log_actor_id_fkey"
            columns: ["actor_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      general_expenses: {
        Row: {
          amount: number
          category: string
          created_at: string
          description: string
          expense_date: string
          id: string
          treasury_transaction_id: string | null
          updated_at: string
        }
        Insert: {
          amount: number
          category: string
          created_at?: string
          description: string
          expense_date?: string
          id?: string
          treasury_transaction_id?: string | null
          updated_at?: string
        }
        Update: {
          amount?: number
          category?: string
          created_at?: string
          description?: string
          expense_date?: string
          id?: string
          treasury_transaction_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "general_expenses_treasury_transaction_id_fkey"
            columns: ["treasury_transaction_id"]
            isOneToOne: false
            referencedRelation: "treasury_transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      idempotency_keys: {
        Row: {
          action: string
          created_at: string
          expires_at: string
          key: string
          response_payload: Json | null
          status: string
          user_id: string | null
        }
        Insert: {
          action: string
          created_at?: string
          expires_at?: string
          key: string
          response_payload?: Json | null
          status: string
          user_id?: string | null
        }
        Update: {
          action?: string
          created_at?: string
          expires_at?: string
          key?: string
          response_payload?: Json | null
          status?: string
          user_id?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "idempotency_keys_user_id_fkey"
            columns: ["user_id"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      profiles: {
        Row: {
          created_at: string
          full_name: string
          id: string
          role: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          full_name: string
          id: string
          role: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          full_name?: string
          id?: string
          role?: string
          updated_at?: string
        }
        Relationships: []
      }
      project_cost_adjustments: {
        Row: {
          adjustment_type: string
          amount: number
          created_at: string
          id: string
          is_voided: boolean
          notes: string | null
          operating_cycle_id: string | null
          project_id: string | null
          surplus_id: string | null
          updated_at: string
          void_reason: string | null
          voided_at: string | null
          voided_by: string | null
        }
        Insert: {
          adjustment_type: string
          amount: number
          created_at?: string
          id?: string
          is_voided?: boolean
          notes?: string | null
          operating_cycle_id?: string | null
          project_id?: string | null
          surplus_id?: string | null
          updated_at?: string
          void_reason?: string | null
          voided_at?: string | null
          voided_by?: string | null
        }
        Update: {
          adjustment_type?: string
          amount?: number
          created_at?: string
          id?: string
          is_voided?: boolean
          notes?: string | null
          operating_cycle_id?: string | null
          project_id?: string | null
          surplus_id?: string | null
          updated_at?: string
          void_reason?: string | null
          voided_at?: string | null
          voided_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "project_cost_adjustments_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "project_cost_adjustments_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "v_project_direct_costs"
            referencedColumns: ["project_id"]
          },
          {
            foreignKeyName: "project_cost_adjustments_surplus_id_fkey"
            columns: ["surplus_id"]
            isOneToOne: false
            referencedRelation: "surplus_bank"
            referencedColumns: ["id"]
          },
        ]
      }
      operating_allocation_cycles: {
        Row: {
          created_at: string
          created_by: string | null
          eligible_project_ids: string[] | null
          id: string
          is_voided: boolean
          notes: string | null
          status: string
          total_amount: number
          updated_at: string
          void_reason: string | null
          voided_at: string | null
          voided_by: string | null
          year_month: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          eligible_project_ids?: string[] | null
          id?: string
          is_voided?: boolean
          notes?: string | null
          status: string
          total_amount?: number
          updated_at?: string
          void_reason?: string | null
          voided_at?: string | null
          voided_by?: string | null
          year_month: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          eligible_project_ids?: string[] | null
          id?: string
          is_voided?: boolean
          notes?: string | null
          status?: string
          total_amount?: number
          updated_at?: string
          void_reason?: string | null
          voided_at?: string | null
          voided_by?: string | null
          year_month?: string
        }
        Relationships: [
          {
            foreignKeyName: "operating_allocation_cycles_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          }
        ]
      }
      portfolio_entries: {
        Row: {
          completed_at: string
          created_at: string
          created_by: string | null
          display_title: string
          id: string
          project_id: string
          public_description: string | null
          updated_at: string
        }
        Insert: {
          completed_at?: string
          created_at?: string
          created_by?: string | null
          display_title: string
          id?: string
          project_id: string
          public_description?: string | null
          updated_at?: string
        }
        Update: {
          completed_at?: string
          created_at?: string
          created_by?: string | null
          display_title?: string
          id?: string
          project_id?: string
          public_description?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "portfolio_entries_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "portfolio_entries_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: true
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
        ]
      }
      portfolio_photos: {
        Row: {
          alt_text: string | null
          created_at: string
          created_by: string | null
          entry_id: string
          id: string
          sort_order: number
          storage_path: string
        }
        Insert: {
          alt_text?: string | null
          created_at?: string
          created_by?: string | null
          entry_id: string
          id?: string
          sort_order?: number
          storage_path: string
        }
        Update: {
          alt_text?: string | null
          created_at?: string
          created_by?: string | null
          entry_id?: string
          id?: string
          sort_order?: number
          storage_path?: string
        }
        Relationships: [
          {
            foreignKeyName: "portfolio_photos_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "portfolio_photos_entry_id_fkey"
            columns: ["entry_id"]
            isOneToOne: false
            referencedRelation: "portfolio_entries"
            referencedColumns: ["id"]
          },
        ]
      }
      operating_allocation_exclusions: {
        Row: {
          created_at: string
          created_by: string | null
          id: string
          project_id: string
          reason: string | null
          year_month: string
        }
        Insert: {
          created_at?: string
          created_by?: string | null
          id?: string
          project_id: string
          reason?: string | null
          year_month: string
        }
        Update: {
          created_at?: string
          created_by?: string | null
          id?: string
          project_id?: string
          reason?: string | null
          year_month?: string
        }
        Relationships: [
          {
            foreignKeyName: "operating_allocation_exclusions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "operating_allocation_exclusions_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          }
        ]
      }
      projects: {
        Row: {
          created_at: string
          description: string | null
          id: string
          name: string
          status: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          description?: string | null
          id?: string
          name: string
          status?: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          description?: string | null
          id?: string
          name?: string
          status?: string
          updated_at?: string
        }
        Relationships: []
      }
      settings: {
        Row: {
          created_at: string
          id: string
          overhead_percentage: number
          updated_at: string
        }
        Insert: {
          created_at?: string
          id?: string
          overhead_percentage?: number
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          overhead_percentage?: number
          updated_at?: string
        }
        Relationships: []
      }
      subcontract_orders: {
        Row: {
          contractor_name: string
          created_at: string
          description: string
          id: string
          project_id: string
          status: string
          total_agreed_amount: number
          updated_at: string
        }
        Insert: {
          contractor_name: string
          created_at?: string
          description: string
          id?: string
          project_id: string
          status?: string
          total_agreed_amount: number
          updated_at?: string
        }
        Update: {
          contractor_name?: string
          created_at?: string
          description?: string
          id?: string
          project_id?: string
          status?: string
          total_agreed_amount?: number
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "subcontract_orders_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subcontract_orders_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "v_project_direct_costs"
            referencedColumns: ["project_id"]
          },
        ]
      }
      subcontract_payments: {
        Row: {
          amount: number
          created_at: string
          id: string
          is_voided: boolean
          notes: string | null
          payment_date: string
          subcontract_order_id: string
          treasury_transaction_id: string | null
          updated_at: string
        }
        Insert: {
          amount: number
          created_at?: string
          id?: string
          is_voided?: boolean
          notes?: string | null
          payment_date?: string
          subcontract_order_id: string
          treasury_transaction_id?: string | null
          updated_at?: string
        }
        Update: {
          amount?: number
          created_at?: string
          id?: string
          is_voided?: boolean
          notes?: string | null
          payment_date?: string
          subcontract_order_id?: string
          treasury_transaction_id?: string | null
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "subcontract_payments_subcontract_order_id_fkey"
            columns: ["subcontract_order_id"]
            isOneToOne: false
            referencedRelation: "subcontract_orders"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "subcontract_payments_treasury_transaction_id_fkey"
            columns: ["treasury_transaction_id"]
            isOneToOne: false
            referencedRelation: "treasury_transactions"
            referencedColumns: ["id"]
          },
        ]
      }
      surplus_bank: {
        Row: {
          created_at: string
          estimated_value: number
          id: string
          initial_quantity: number
          material_name: string
          notes: string | null
          parent_surplus_id: string | null
          quantity: number
          source_project_id: string | null
          status: string
          unit: string
          updated_at: string
        }
        Insert: {
          created_at?: string
          estimated_value: number
          id?: string
          initial_quantity: number
          material_name: string
          notes?: string | null
          parent_surplus_id?: string | null
          quantity: number
          source_project_id?: string | null
          status?: string
          unit: string
          updated_at?: string
        }
        Update: {
          created_at?: string
          estimated_value?: number
          id?: string
          initial_quantity?: number
          material_name?: string
          notes?: string | null
          parent_surplus_id?: string | null
          quantity?: number
          source_project_id?: string | null
          status?: string
          unit?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "surplus_bank_parent_surplus_id_fkey"
            columns: ["parent_surplus_id"]
            isOneToOne: false
            referencedRelation: "surplus_bank"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "surplus_bank_source_project_id_fkey"
            columns: ["source_project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "surplus_bank_source_project_id_fkey"
            columns: ["source_project_id"]
            isOneToOne: false
            referencedRelation: "v_project_direct_costs"
            referencedColumns: ["project_id"]
          },
        ]
      }
      treasury_transactions: {
        Row: {
          amount: number
          category: string
          subcategory: string | null
          created_at: string
          created_by: string | null
          description: string | null
          id: string
          is_direct_owner_payment: boolean
          is_voided: boolean
          project_id: string | null
          transaction_type: string
          updated_at: string
          void_reason: string | null
          voided_at: string | null
          voided_by: string | null
        }
        Insert: {
          amount: number
          category: string
          subcategory?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          is_direct_owner_payment?: boolean
          is_voided?: boolean
          project_id?: string | null
          transaction_type: string
          updated_at?: string
          void_reason?: string | null
          voided_at?: string | null
          voided_by?: string | null
        }
        Update: {
          amount?: number
          category?: string
          subcategory?: string | null
          created_at?: string
          created_by?: string | null
          description?: string | null
          id?: string
          is_direct_owner_payment?: boolean
          is_voided?: boolean
          project_id?: string | null
          transaction_type?: string
          updated_at?: string
          void_reason?: string | null
          voided_at?: string | null
          voided_by?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "treasury_transactions_created_by_fkey"
            columns: ["created_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "treasury_transactions_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "treasury_transactions_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "v_project_direct_costs"
            referencedColumns: ["project_id"]
          },
          {
            foreignKeyName: "treasury_transactions_voided_by_fkey"
            columns: ["voided_by"]
            isOneToOne: false
            referencedRelation: "profiles"
            referencedColumns: ["id"]
          },
        ]
      }
      worker_advances: {
        Row: {
          advance_date: string
          amount: number
          created_at: string
          id: string
          is_carried_forward: boolean
          is_settled: boolean
          notes: string | null
          settlement_id: string | null
          treasury_transaction_id: string | null
          updated_at: string
          worker_id: string
        }
        Insert: {
          advance_date?: string
          amount: number
          created_at?: string
          id?: string
          is_carried_forward?: boolean
          is_settled?: boolean
          notes?: string | null
          settlement_id?: string | null
          treasury_transaction_id?: string | null
          updated_at?: string
          worker_id: string
        }
        Update: {
          advance_date?: string
          amount?: number
          created_at?: string
          id?: string
          is_carried_forward?: boolean
          is_settled?: boolean
          notes?: string | null
          settlement_id?: string | null
          treasury_transaction_id?: string | null
          updated_at?: string
          worker_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "worker_advances_treasury_transaction_id_fkey"
            columns: ["treasury_transaction_id"]
            isOneToOne: false
            referencedRelation: "treasury_transactions"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "worker_advances_worker_id_fkey"
            columns: ["worker_id"]
            isOneToOne: false
            referencedRelation: "workers"
            referencedColumns: ["id"]
          },
        ]
      }
      worker_logs: {
        Row: {
          calculated_amount: number
          created_at: string
          daily_rate: number
          fraction: number
          id: string
          is_settled: boolean
          log_date: string
          notes: string | null
          project_id: string | null
          settlement_id: string | null
          updated_at: string
          worker_id: string
        }
        Insert: {
          calculated_amount?: number
          created_at?: string
          daily_rate: number
          fraction: number
          id?: string
          is_settled?: boolean
          log_date?: string
          notes?: string | null
          project_id?: string | null
          settlement_id?: string | null
          updated_at?: string
          worker_id: string
        }
        Update: {
          calculated_amount?: number
          created_at?: string
          daily_rate?: number
          fraction?: number
          id?: string
          is_settled?: boolean
          log_date?: string
          notes?: string | null
          project_id?: string | null
          settlement_id?: string | null
          updated_at?: string
          worker_id?: string
        }
        Relationships: [
          {
            foreignKeyName: "worker_logs_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "projects"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "worker_logs_project_id_fkey"
            columns: ["project_id"]
            isOneToOne: false
            referencedRelation: "v_project_direct_costs"
            referencedColumns: ["project_id"]
          },
          {
            foreignKeyName: "worker_logs_worker_id_fkey"
            columns: ["worker_id"]
            isOneToOne: false
            referencedRelation: "workers"
            referencedColumns: ["id"]
          },
        ]
      }
      workers: {
        Row: {
          created_at: string
          daily_rate: number
          id: string
          is_active: boolean
          name: string
          phone: string | null
          updated_at: string
        }
        Insert: {
          created_at?: string
          daily_rate: number
          id?: string
          is_active?: boolean
          name: string
          phone?: string | null
          updated_at?: string
        }
        Update: {
          created_at?: string
          daily_rate?: number
          id?: string
          is_active?: boolean
          name?: string
          phone?: string | null
          updated_at?: string
        }
        Relationships: []
      }
    }
    Views: {
      v_pending_liabilities: {
        Row: {
          total_pending_liabilities: number | null
          total_subcontract_liabilities: number | null
          total_worker_liabilities: number | null
        }
        Relationships: []
      }
      v_worker_liabilities: {
        Row: {
          carried_forward_credit: number | null
          net_payable: number | null
          unsettled_advances: number | null
          unsettled_wages: number | null
          worker_id: string | null
        }
        Relationships: []
      }
      v_surplus_available: {
        Row: {
          item_count: number | null
          total_surplus_quantity: number | null
          total_surplus_value: number | null
        }
        Relationships: []
      }
      v_surplus_status_stats: {
        Row: {
          item_count: number | null
          status: string | null
          total_estimated_value: number | null
        }
        Relationships: []
      }
      v_portfolio_gallery_public: {
        Row: {
          alt_text: string | null
          completed_at: string | null
          display_title: string | null
          entry_id: string | null
          public_description: string | null
          sort_order: number | null
          storage_path: string | null
        }
        Relationships: []
      }
      v_project_direct_costs: {
        Row: {
          direct_project_cost: number | null
          estimated_total_cost: number | null
          freight_cost: number | null
          labor_cost: number | null
          material_cost: number | null
          operating_cost: number | null
          overhead_percentage: number | null
          project_id: string | null
          project_name: string | null
          project_status: string | null
          subcontract_cost: number | null
          surplus_consumptions: number | null
          surplus_returns: number | null
        }
        Relationships: []
      }
      v_treasury_balance: {
        Row: {
          current_balance: number | null
          total_in: number | null
          total_out: number | null
        }
        Relationships: []
      }
      v_monthly_treasury_stats: {
        Row: {
          month: string | null
          total_in: number | null
          total_out: number | null
        }
        Relationships: []
      }
      v_project_profitability: {
        Row: {
          project_id: string | null
          project_name: string | null
          estimated_total_cost: number | null
          total_revenue: number | null
          net_profit: number | null
        }
        Relationships: []
      }
      v_worker_performance_stats: {
        Row: {
          worker_id: string | null
          worker_name: string | null
          month: string | null
          total_days: number | null
          total_wages: number | null
          total_advances: number | null
        }
        Relationships: []
      }
    }
    Functions: {
      rpc_correct_attendance: {
        Args: {
          p_log_id: string
          p_new_fraction: number
          p_new_project_id?: string | null
          p_correction_reason?: string | null
        }
        Returns: Json
      }
      rpc_close_subcontract_order: {
        Args: { p_order_id: string; p_status?: string; p_reason?: string }
        Returns: Json
      }
      rpc_consume_surplus: {
        Args: {
          p_consume_qty: number
          p_notes?: string
          p_surplus_id: string
          p_target_project_id: string
        }
        Returns: Json
      }
      rpc_return_surplus: {
        Args: {
          p_estimated_value: number
          p_material_name: string
          p_notes?: string
          p_project_id: string
          p_quantity: number
          p_unit: string
        }
        Returns: Json
      }
      rpc_scrap_surplus: {
        Args: { p_notes?: string; p_surplus_id: string }
        Returns: Json
      }
      rpc_create_subcontract_order: {
        Args: {
          p_contractor_name: string
          p_description: string
          p_project_id: string
          p_total_agreed_amount: number
        }
        Returns: Json
      }
      rpc_pay_subcontract: {
        Args: {
          p_amount: number
          p_notes?: string
          p_order_id: string
          p_payment_date: string
        }
        Returns: Json
      }
      rpc_record_advance: {
        Args: {
          p_advance_date: string
          p_amount: number
          p_notes?: string
          p_worker_id: string
        }
        Returns: Json
      }
      rpc_record_attendance: {
        Args: {
          p_fraction: number
          p_project_id?: string | null
          p_worker_id: string
          p_work_date: string
        }
        Returns: Json
      }
      rpc_add_operating_exclusion: {
        Args: { p_project_id: string; p_reason?: string; p_year_month: string }
        Returns: Json
      },
      rpc_remove_operating_exclusion: {
        Args: { p_project_id: string; p_year_month: string; p_reason?: string }
        Returns: Json
      },
      rpc_run_operating_allocation: {
        Args: { p_year_month: string }
        Returns: Json
      },
      rpc_void_allocation_cycle: {
        Args: { p_cycle_id: string; p_reason?: string }
        Returns: Json
      },
      rpc_void_allocation_line: {
        Args: { p_adjustment_id: string; p_reason?: string }
        Returns: Json
      },
      rpc_settle_worker: {
        Args: { p_notes?: string; p_worker_id: string }
        Returns: Json
      }
      rpc_void_subcontract_payment: {
        Args: { p_payment_id: string; p_reason?: string }
        Returns: Json
      },
      increment_rate_limit: {
        Args: { p_bucket: string; p_limit: number; p_window_seconds?: number }
        Returns: Json
      }
      rpc_record_treasury_transaction: {
        Args: {
          p_idempotency_key: string
          p_action: string
          p_transaction_type: string
          p_category: string
          p_subcategory?: string | null
          p_amount: number
          p_project_id?: string | null
          p_is_direct_owner: boolean
          p_description?: string | null
        }
        Returns: Json
      }
      rpc_void_treasury_transaction: {
        Args: {
          p_idempotency_key: string
          p_action: string
          p_transaction_id: string
          p_reason: string
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  app_private: {
    Enums: {},
  },
  public: {
    Enums: {},
  },
} as const

